#!/bin/perl
#
#  Regression tests for bundled index source-view opt-in.
#
use strict qw(vars);
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use bin_helper qw(run_cmd write_file);
use File::Spec;
use File::Temp qw(tempdir);
use Data::Dumper;


BEGIN {
    my @missing;
    for my $m (qw(Plack::Test Plack::Request Plack::Response HTTP::Request::Common)) {
        eval "require $m; 1" or push @missing, $m;
    }
    plan skip_all => 'Skipping index source test: missing ' . join(', ', @missing)
        if @missing;
}


my $root_dn=tempdir(CLEANUP => 1);
write_file(
    File::Spec->catfile($root_dn, 'app.psp'),
    <<'END_PSP'
<html><body>Hello</body></html>
__PERL__
my $SECRET = "INDEX-SOURCE-SECRET-42";
END_PSP
);


my $default=render_index($root_dn, 0);
like($default->{'listing'}, qr/app\.psp/, 'default index lists files');
unlike($default->{'listing'}, qr/data-filename="app\.psp"/, 'default index does not render source toggle');
unlike($default->{'listing'}, qr/>View<\/th>/, 'default index omits source-view column');
unlike($default->{'source'}, qr/INDEX-SOURCE-SECRET-42/, 'default index source request does not disclose source');
like($default->{'source'}, qr/\[Source view disabled\]/, 'default index source request reports disabled source view');


my $enabled=render_index($root_dn, 1);
like($enabled->{'listing'}, qr/app\.psp/, 'enabled index lists files');
like($enabled->{'listing'}, qr/data-filename="app\.psp"/, 'enabled index renders source toggle');
like($enabled->{'listing'}, qr/>View<\/th>/, 'enabled index renders source-view column');
like($enabled->{'source'}, qr/INDEX-SOURCE-SECRET-42/, 'enabled index source request discloses source by explicit opt-in');
my ($md5_hex)=$enabled->{'listing'} =~ /data-filename="app\.psp"\s+data-md5="([0-9a-f]{32})"/;
ok($md5_hex, 'enabled index renders a source-row digest');
like($enabled->{'source'}, qr/data-md5="$md5_hex"/, 'source response uses the digest rendered by its toggle');


done_testing();


sub render_index {

    my ($root_dn, $source_enable)=@_;
    my $code=<<'END_CODE';
use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use WebDyne::PSGI;
my $root=shift(@ARGV);
my $test=Plack::Test->create(WebDyne::PSGI->new(root => $root, index => 1)->to_app());
my $listing=$test->request(GET('/'))->content();
my $source=$test->request(GET('/?source=app.psp', 'HX-Request' => 'true'))->content();
print "===LISTING===\n$listing\n===SOURCE===\n$source\n";
END_CODE

    my ($stdout, $stderr, $rc);
    {
        local $ENV{'WEBDYNE_CONF'}='.';
        local $ENV{'WEBDYNE_HEAD_INSERT'}=0;
        if ($source_enable) {
            my $conf_fn=File::Spec->catfile($root_dn, 'webdyne-index-source.conf.pl');
            local $Data::Dumper::Terse=1;
            local $Data::Dumper::Sortkeys=1;
            write_file(
                $conf_fn,
                Data::Dumper->Dump([{'WebDyne::Constant' => {WEBDYNE_INDEX_SOURCE_ENABLE => 1}}])
            );
            $ENV{'WEBDYNE_CONF'}=$conf_fn;
        }
        ($stdout, $stderr, $rc)=run_cmd($^X, '-Ilib', '-e', $code, $root_dn);
    }
    is($rc, 0, 'index render subprocess exits cleanly');
    is($stderr, '', 'index render subprocess writes no stderr');
    my ($listing)=$stdout=~/===LISTING===\n(.*?)\n===SOURCE===\n/s;
    my ($source)=$stdout=~/===SOURCE===\n(.*)\z/s;
    return {
        listing => $listing || '',
        source  => $source || ''
    };

}

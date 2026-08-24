#!/bin/perl
#
#  Regression tests for sticky CGI form field escaping.
#
use strict qw(vars);
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use bin_helper qw(run_cmd write_file);
use File::Spec;
use File::Temp qw(tempdir);


BEGIN {
    my @missing;
    for my $m (qw(Plack::Test Plack::Request Plack::Response HTTP::Request::Common)) {
        eval "require $m; 1" or push @missing, $m;
    }
    plan skip_all => 'Skipping CGI autoescape test: missing ' . join(', ', @missing)
        if @missing;
}


my $root_dn=tempdir(CLEANUP => 1);
write_file(
    File::Spec->catfile($root_dn, 'form.psp'),
    <<'END_PSP'
<html><body><form>
<textfield name="q">
<password_field name="p">
<filefield name="f">
</form></body></html>
END_PSP
);


my $escaped=render_form($root_dn, undef);
unlike($escaped, qr/value=""><script>alert\(1\)<\/script>"/,
    'default sticky form fields do not reflect raw attribute-breakout payload');
like($escaped, qr/value="&#34;&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;"/,
    'default sticky form fields escape request values');


my $escaped_explicit=render_form($root_dn, 1);
unlike($escaped_explicit, qr/value=""><script>alert\(1\)<\/script>"/,
    'WEBDYNE_CGI_AUTOESCAPE=1 does not reflect raw attribute-breakout payload');
like($escaped_explicit, qr/value="&#34;&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;"/,
    'WEBDYNE_CGI_AUTOESCAPE=1 escapes request values');


my $raw=render_form($root_dn, 0);
like($raw, qr/value=""><script>alert\(1\)<\/script>"/,
    'WEBDYNE_CGI_AUTOESCAPE=0 preserves legacy raw sticky form values');


done_testing();


sub render_form {

    my ($root_dn, $autoescape)=@_;
    my $code=<<'END_CODE';
use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use WebDyne::PSGI;
my $root=shift(@ARGV);
my $query='q=%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E&p=%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E&f=%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E';
my $test=Plack::Test->create(WebDyne::PSGI->new(root => $root)->to_app());
my $res=$test->request(GET "/form.psp?$query");
print $res->content();
END_CODE

    my ($stdout, $stderr, $rc);
    {
        local $ENV{'WEBDYNE_CONF'}='.';
        local $ENV{'WEBDYNE_HEAD_INSERT'}=0;
        if (defined($autoescape)) {
            local $ENV{'WEBDYNE_CGI_AUTOESCAPE'}=$autoescape;
            ($stdout, $stderr, $rc)=run_cmd($^X, '-Ilib', '-e', $code, $root_dn);
        }
        else {
            local %ENV=%ENV;
            delete $ENV{'WEBDYNE_CGI_AUTOESCAPE'};
            ($stdout, $stderr, $rc)=run_cmd($^X, '-Ilib', '-e', $code, $root_dn);
        }
    }
    is($rc, 0, 'form render subprocess exits cleanly');
    is($stderr, '', 'form render subprocess writes no stderr');
    return $stdout;

}

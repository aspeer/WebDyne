use strict;
use warnings;

use Test::More;

BEGIN {
    my @missing;
    for my $m (qw(Plack::Test Plack::Request Plack::Response)) {
        eval "require $m; 1" or push @missing, $m;
    }
    plan skip_all => "Skipping PSGI init test: missing " . join(", ", @missing)
        if @missing;
}

BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
    $ENV{'WEBDYNE_HEAD_INSERT'}=0;
}

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use HTTP::Request::Common qw(GET);
use IO::File;
use Plack::Test;

use WebDyne::PSGI;

ok(${&main() || die 'main failed'} || 0);
done_testing();


sub main {

    my $root_dn=tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($root_dn, 'app.psp'), '<start_html>trial app');
    write_file(File::Spec->catfile($root_dn, 'asset.css'), "body { color: red; }\n");
    write_file(File::Spec->catfile($root_dn, '.webdyne.conf.pl'), <<'END_CONF');
$_={
    'WebDyne::Constant' => {
        WEBDYNE_HTML_DEFAULT_TITLE => 'PSGI Constructor Config Loaded'
    }
};
END_CONF

    is($WebDyne::PSGI::WEBDYNE_PSGI_STATIC, 0,
        'direct WebDyne::PSGI static middleware default is off');

    ok(my $plain_or=WebDyne::PSGI->new(root => $root_dn, index => 'app.psp'),
        'construct PSGI app without conf flag');
    isnt($WebDyne::PSGI::WEBDYNE_HTML_DEFAULT_TITLE,
        'PSGI Constructor Config Loaded',
        'conf file is not loaded by default constructor path');
    ok(my $plain_test_or=Plack::Test->create($plain_or->to_app()),
        'create PSGI client for default constructor app');
    my $res=$plain_test_or->request(GET('/app.psp'));
    is($res->code(), 200, 'default constructor app still renders PSP page');
    like($res->decoded_content() || '', qr/trial app/,
        'default constructor app returns rendered body');

    ok(my $static_or=WebDyne::PSGI->new(root => $root_dn, index => 'app.psp', static => 1),
        'construct PSGI app with static flag');
    ok(my $static_test_or=Plack::Test->create($static_or->to_app()),
        'create PSGI client for static constructor app');
    $res=$static_test_or->request(GET('/asset.css'));
    is($res->code(), 200, 'static flag serves static asset');
    is($res->decoded_content(), "body { color: red; }\n",
        'static asset body is served by middleware');

    ok(my $conf_or=WebDyne::PSGI->new(root => $root_dn, index => 'app.psp', conf => 1),
        'construct PSGI app with root conf flag');
    is($WebDyne::PSGI::WEBDYNE_HTML_DEFAULT_TITLE,
        'PSGI Constructor Config Loaded',
        'conf => 1 loads root .webdyne.conf.pl');
    ok($conf_or, 'conf constructor returns object');

    return \1;
}


sub write_file {

    my ($fn, $content)=@_;
    my ($volume, $directory)=File::Spec->splitpath($fn);
    make_path($directory) if length($directory) && !-d $directory;
    my $fh=IO::File->new($fn, O_WRONLY|O_CREAT|O_TRUNC) ||
        die "unable to write $fn, $!";
    print {$fh} $content;
    $fh->close();
    return $fn;

}

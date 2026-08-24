use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use pagi_compat_helper qw(pagi_skip_reason);

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Test::Client PAGI::Middleware::Builder PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI init test: $skip" if $skip;
}

BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
    $ENV{'WEBDYNE_HEAD_INSERT'}=0;
}

use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::File;

use WebDyne::PAGI;

ok(${&main() || die 'main failed'} || 0);
done_testing();


sub main {

    my $root_dn=tempdir(CLEANUP => 1);
    write_file(File::Spec->catfile($root_dn, 'app.psp'), '<start_html>trial app');
    write_file(File::Spec->catfile($root_dn, 'asset.css'), "body { color: red; }\n");
    write_file(File::Spec->catfile($root_dn, 'secret.dat'), "constructor static secret\n");
    write_file(File::Spec->catfile($root_dn, '.webdyne.conf.pl'), <<'END_CONF');
$_={
    'WebDyne::Constant' => {
        WEBDYNE_HTML_DEFAULT_TITLE => 'PAGI Constructor Config Loaded'
    }
};
END_CONF

    is($WebDyne::PAGI::WEBDYNE_PAGI_STATIC, 0,
        'direct WebDyne::PAGI static middleware default is off');

    ok(my $plain_or=WebDyne::PAGI->new(root => $root_dn, index => 'app.psp'),
        'construct PAGI app without conf flag');
    isnt($WebDyne::PAGI::WEBDYNE_HTML_DEFAULT_TITLE,
        'PAGI Constructor Config Loaded',
        'conf file is not loaded by default constructor path');
    ok(my $plain_test_or=PAGI::Test::Client->new(app => $plain_or->to_app()),
        'create PAGI client for default constructor app');
    my $res=$plain_test_or->get('/app.psp');
    is($res->{'status'}, 200, 'default constructor app still renders PSP page');
    like($res->{'body'} || '', qr/trial app/,
        'default constructor app returns rendered body');

    ok(my $static_or=WebDyne::PAGI->new(root => $root_dn, index => 'app.psp', static => 1),
        'construct PAGI app with static flag');
    ok(my $static_test_or=PAGI::Test::Client->new(app => $static_or->to_app()),
        'create PAGI client for static constructor app');
    $res=$static_test_or->get('/asset.css');
    is($res->{'status'}, 200, 'static flag serves static asset');
    is($res->{'body'}, "body { color: red; }\n",
        'static asset body is served by middleware');
    $res=$static_test_or->get('/secret.dat');
    isnt($res->{'status'}, 200, 'static flag does not serve disallowed static extension');
    unlike($res->{'body'} || '', qr/constructor static secret/,
        'disallowed static asset body is not leaked');

    ok(my $conf_or=WebDyne::PAGI->new(root => $root_dn, index => 'app.psp', conf => 1),
        'construct PAGI app with root conf flag');
    is($WebDyne::PAGI::WEBDYNE_HTML_DEFAULT_TITLE,
        'PAGI Constructor Config Loaded',
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

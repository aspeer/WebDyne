#!/bin/perl
#
#  Regression tests for WebDyne::Session cookie security attributes.
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
    for my $m (qw(Plack::Test Plack::Request Plack::Response HTTP::Request::Common Crypt::URandom)) {
        eval "require $m; 1" or push @missing, $m;
    }
    plan skip_all => 'Skipping session cookie flag test: missing ' . join(', ', @missing)
        if @missing;
}


my $root_dn=tempdir(CLEANUP => 1);
write_file(
    File::Spec->catfile($root_dn, 'session.psp'),
    <<'END_PSP'
<html><body>Session ID: <? shift()->session_id() ?></body></html>
__PERL__
use WebDyne::Session;
END_PSP
);


my $default_cookie=render_session($root_dn, {});
like($default_cookie, qr/\bsession=[0-9a-f]{32}\b/, 'default cookie contains generated session id');
like($default_cookie, qr/;\s*path=\//i, 'default cookie uses path /');
like($default_cookie, qr/;\s*secure\b/i, 'default cookie has Secure flag');
like($default_cookie, qr/;\s*HttpOnly\b/i, 'default cookie has HttpOnly flag');
like($default_cookie, qr/;\s*SameSite=Lax\b/i, 'default cookie has SameSite=Lax');


my $custom_cookie=render_session($root_dn, {
    WEBDYNE_SESSION_ID_COOKIE_NAME => 'gingernut',
    WEBDYNE_SESSION_COOKIE_PATH    => '/app',
});
like($custom_cookie, qr/\bgingernut=[0-9a-f]{32}\b/, 'custom cookie name is used');
like($custom_cookie, qr/;\s*path=\/app\b/i, 'custom cookie path is used');


my $relaxed_cookie=render_session($root_dn, {
    WEBDYNE_SESSION_COOKIE_SECURE   => 0,
    WEBDYNE_SESSION_COOKIE_HTTPONLY => 0,
    WEBDYNE_SESSION_COOKIE_SAMESITE => '',
});
unlike($relaxed_cookie, qr/;\s*secure\b/i, 'Secure flag can be disabled');
unlike($relaxed_cookie, qr/;\s*HttpOnly\b/i, 'HttpOnly flag can be disabled');
unlike($relaxed_cookie, qr/;\s*SameSite=/i, 'SameSite attribute can be omitted');


done_testing();


sub render_session {

    my ($root_dn, $env_hr)=@_;
    my $code=<<'END_CODE';
use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use WebDyne::PSGI;
my $root=shift(@ARGV);
my $test=Plack::Test->create(WebDyne::PSGI->new(root => $root)->to_app());
my $res=$test->request(GET('/session.psp'));
my $cookie=$res->header('Set-Cookie') || '';
print $cookie;
END_CODE

    my ($stdout, $stderr, $rc);
    {
        local $ENV{'WEBDYNE_CONF'}='.';
        local $ENV{'WEBDYNE_HEAD_INSERT'}=0;
        if (keys %{$env_hr}) {
            my $conf_fn=File::Spec->catfile($root_dn, 'webdyne-session-test.conf.pl');
            local $Data::Dumper::Terse=1;
            local $Data::Dumper::Sortkeys=1;
            write_file(
                $conf_fn,
                Data::Dumper->Dump([{'WebDyne::Session::Constant' => $env_hr}])
            );
            $ENV{'WEBDYNE_CONF'}=$conf_fn;
        }
        ($stdout, $stderr, $rc)=run_cmd($^X, '-Ilib', '-e', $code, $root_dn);
    }
    is($rc, 0, 'session render subprocess exits cleanly');
    is($stderr, '', 'session render subprocess writes no stderr');
    return $stdout;

}

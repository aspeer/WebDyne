use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping WebSocket denial test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
}

use WebDyne::PAGI;
use Future;
use PAGI::Test::ConnectionState;

my $root_dn=tempdir(CLEANUP => 1);
my $app_cr=WebDyne::PAGI->new(root => $root_dn, static => 0)->to_app();
foreach my $case_ar (
    ['missing page', undef],
    ['forbidden', 403],
    ['undefined', undef],
    ['invalid', 'invalid'],
    ['no callback', 100],
    ['ordinary success', 200],
) {
    my ($name, $status)=@{$case_ar};
    my @event;
    my $send_or=Future->new();
    my $run_cr=sub {
        return $app_cr->(
            {type => 'websocket', path => '/missing.psp', query_string => '', headers => [],
                'pagi.connection' => PAGI::Test::ConnectionState->new(websocket => 1)},
            sub { Future->done({type => 'websocket.connect'}) },
            sub { push @event, shift(); return $send_or },
        );
    };
    my $application_or;
    if ($name eq 'missing page') {
        $application_or=$run_cr->();
    }
    else {
        no warnings 'redefine';
        local *WebDyne::handler=sub { return $status };
        $application_or=$run_cr->();
    }
    is(scalar(@event), 1, "$name refuses without accepting");
    is($event[0]->{'type'}, 'http.response.start', "$name refuses with an HTTP response");
    is($event[0]->{'status'}, 403, "$name refuses with 403");
    ok(!$application_or->is_ready(), "$name awaits refusal send");
    $send_or->done();
    is($event[1]->{'type'}, 'http.response.body', "$name sends the refusal body");
    ok($application_or->is_done(), "$name completes after refusal send resolves");
    $application_or->get();
}

done_testing();

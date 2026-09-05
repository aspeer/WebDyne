use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping SSE denial test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
}

use WebDyne::PAGI;
use Future;

my $root_dn=tempdir(CLEANUP => 1);
my $app_cr=WebDyne::PAGI->new(root => $root_dn, static => 0)->to_app();
foreach my $case_ar (
    ['missing page', undef, 404],
    ['forbidden', 403, 403],
    ['unavailable', 503, 503],
    ['undefined', undef, 500],
    ['invalid', 'invalid', 500],
    ['no callback', 100, 500],
    ['ordinary success', 200, 500],
) {
    my ($name, $returned, $expected)=@{$case_ar};
    my (@event, @send);
    my $run_cr=sub {
        return $app_cr->(
            {type => 'sse', method => 'GET', path => '/missing.psp', query_string => '', headers => []},
            sub { die 'denial should not read input' },
            sub {
                push @event, shift();
                my $send_or=Future->new();
                push @send, $send_or;
                return $send_or;
            },
        );
    };
    my $application_or;
    if ($name eq 'missing page') {
        $application_or=$run_cr->();
    }
    else {
        no warnings 'redefine';
        local *WebDyne::handler=sub { return $returned };
        $application_or=$run_cr->();
    }
    is(scalar(@event), 1, "$name waits before sending body");
    is($event[0]->{'type'}, 'sse.http.response.start', "$name sends denial start");
    is($event[0]->{'status'}, $expected, "$name preserves or normalizes status");
    ok(!$application_or->is_ready(), "$name awaits start send");
    $send[0]->done();
    is(scalar(@event), 2, "$name sends body after start settles");
    is($event[1]->{'type'}, 'sse.http.response.body', "$name sends denial body");
    like($event[1]->{'body'}, qr/^$expected .+\n$/, "$name returns a plain-text status");
    is($event[1]->{'more'}, 0, "$name terminates response");
    ok(!$application_or->is_ready(), "$name awaits body send");
    $send[1]->done();
    ok($application_or->is_done(), "$name completes after both sends");
    $application_or->get();
}

done_testing();

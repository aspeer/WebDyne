#  Pragma
#
use strict;
use warnings;


#  Test Harness
#
use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use pagi_compat_helper qw(pagi_skip_reason);


#  Skip test if missing modules
#
BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Test::Client PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI SSE test: $skip" if $skip;
}


#  Skip any local config
#
BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
}


#  Modules we need
#
use File::Spec;
use File::Temp qw(tempdir);
use IO::File;
use Future;


#  Load WebDyne modules we need
#
use WebDyne::PAGI;


#  Run tests
#
ok(${&main() || die 'main failed'} || 0);
done_testing();


#======================================================================================================================


sub main {

    my $root_dn=tempdir(CLEANUP => 1);
    my $page_fn=File::Spec->catfile($root_dn, 'sse.psp');
    ok(my $page_fh=IO::File->new($page_fn, O_WRONLY|O_CREAT|O_TRUNC), 'create temporary SSE page');
    print {$page_fh} <<'EOF';
<start_html sse>
__PERL__
use Future::AsyncAwait;
use HTTP::Status qw(HTTP_OK);

async sub sse {
    my ($self, $param_hr)=@_;
    my $sse_or=$self->r()->sse();
    await $sse_or->start(
        status  => HTTP_OK,
        headers => [
            ['content-type' => 'text/event-stream'],
            ['cache-control' => 'no-cache'],
        ],
    );
    await $sse_or->send_event(event => 'tick', data => join(':', $param_hr->{'one'}, $param_hr->{'two'}));
    await $sse_or->close();
}
EOF
    $page_fh->close();

    ok(my $app_cr=WebDyne::PAGI->new(root => $root_dn)->to_app(), 'build PAGI app');
    ok(my $test_or=PAGI::Test::Client->new(app => $app_cr), 'create PAGI test client');

    $test_or->sse('/sse.psp?one=alpha&two=bravo', sub {
        my $sse=shift();

        is($sse->{'status'}, 200, 'SSE transport returns HTTP 200');
        my $headers_ar=$sse->{'headers'} || [];
        ok(
            scalar(grep {
                lc($_->[0]) eq 'content-type' && $_->[1] =~ m{text/event-stream}i
            } @{$headers_ar}),
            'SSE transport advertises text/event-stream'
        );

        my $event=$sse->receive_event();
        is($event->{'event'}, 'tick', 'SSE event name is correct');
        is($event->{'data'}, 'alpha:bravo', 'SSE handler receives param hash');
    });

    #  A pending transport send must keep the application alive through close.
    #  Immediately resolved test sends would conceal a missing await above.
    #
    my $close_or=Future->new();
    my @event;
    my $application_or=$app_cr->(
        {type => 'sse', method => 'GET', path => '/sse.psp',
            query_string => 'one=alpha&two=bravo', headers => []},
        sub { Future->new() },
        sub {
            my $event_hr=shift();
            push @event, $event_hr->{'type'};
            return $event_hr->{'type'} eq 'sse.close' ? $close_or : Future->done();
        },
    );
    is_deeply(\@event, [qw(sse.start sse.send sse.close)], 'SSE sends start, event and close in order');
    ok(!$application_or->is_ready(), 'application waits for pending close send');
    $close_or->done();
    ok($application_or->is_done(), 'application completes after close send resolves');
    $application_or->get();

    return \1;
}

use strict;
use warnings;
use Test::More;
use sort 'stable';

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI header test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use WebDyne::PAGI;
use Future;

my $app_cr=WebDyne::PAGI->new(root => '.', static => 0)->to_app();
foreach my $failure (0, 1, 2) {
    my (@event, @send);
    my $headers_or;
    my $application_or;
    {
        no warnings 'redefine';
        local *WebDyne::handler=sub {
            my ($class, $request_or)=@_;
            $headers_or=$request_or->headers_out();
            $headers_or->push_header('X-Mixed' => 'VaLuE');
            $headers_or->push_header('X-Mixed' => 'second');
            $headers_or->push_header('X-Empty' => '');
            return 200;
        };
        $application_or=$app_cr->(
            {type => 'http', method => 'GET', path => '/headers.psp', headers => []},
            sub { Future->done({type => 'http.request', body => '', more => 0}) },
            sub {
                push @event, shift();
                my $send_or=Future->new();
                push @send, $send_or;
                return $send_or;
            },
        );
    }
    #  Headers of different names have no defined order; repeated values of
    #  one name keep theirs. A stable sort by name compares only that.
    #
    my @custom=sort { $a->[0] cmp $b->[0] } grep { $_->[0] =~ /^x-/ } @{$event[0]->{'headers'}};
    is_deeply(\@custom, [['x-empty', ''], ['x-mixed', 'VaLuE'], ['x-mixed', 'second']], 'outgoing names normalized without changing values or order');
    my $stored_ar=$headers_or->psgi_flatten_without_sort();
    my @stored=sort { $a->[0] cmp $b->[0] } grep { $_->[0] =~ /^X-/ } map { [@{$stored_ar}[$_*2, $_*2+1]] } 0 .. @{$stored_ar}/2-1;
    is_deeply(\@stored, [['X-Empty', ''], ['X-Mixed', 'VaLuE'], ['X-Mixed', 'second']], 'stored headers retain original names');
    ok(!$application_or->is_ready(), 'application awaits start send');
    if ($failure == 2) {
        $send[0]->done();
        ok(!$application_or->is_ready(), 'application awaits body send before failure');
        $send[1]->fail('test body send failure');
        ok($application_or->is_failed(), 'body send failure propagates');
        like(scalar($application_or->failure()), qr/test body send failure/, 'original body send failure retained');
        is(scalar(@event), 2, 'no extra events sent after failed body');
    }
    elsif ($failure) {
        $send[0]->fail('test send failure');
        ok($application_or->is_failed(), 'send failure propagates');
        like(scalar($application_or->failure()), qr/test send failure/, 'original send failure retained');
        is(scalar(@event), 1, 'no body sent after failed start');
    }
    else {
        $send[0]->done();
        is_deeply($event[1], {type => 'http.response.body', body => '', more => 0}, 'body event passes through');
        ok(!$application_or->is_ready(), 'application awaits body send');
        $send[1]->done();
        ok($application_or->is_done(), 'application completes after body send');
        $application_or->get();
    }
}

done_testing();

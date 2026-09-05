use strict;
use warnings;

use Test::More;

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI cookie test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use WebDyne::PAGI;
use Future;
use HTTP::Status qw(HTTP_OK);

my $app_cr=WebDyne::PAGI->new(root => '.', static => 0)->to_app();
foreach my $case (qw(multiple identical response_only)) {
    my @event;
    {
        no warnings 'redefine';
        local *WebDyne::handler=sub {
            my ($class, $request_or)=@_;
            my $headers_or=$request_or->headers_out();
            $request_or->res()->header('X-Test' => 'original');
            $headers_or->header('X-Test' => 'replacement');
            $request_or->res()->header('Set-Cookie' => 'existing=1');
            unless ($case eq 'response_only') {
                $headers_or->push_header('Set-Cookie' => 'a=1');
                $headers_or->push_header('set-cookie' => $case eq 'identical' ? 'a=1' : 'b=2');
            }
            return HTTP_OK;
        };
        $app_cr->(
            {type => 'http', method => 'GET', path => '/cookies.psp', headers => [], query_string => ''},
            sub { Future->done({type => 'http.request', body => '', more => 0}) },
            sub { push @event, shift(); Future->done() },
        )->get();
    }
    my @cookie=map { $_->[1] } grep { lc($_->[0]) eq 'set-cookie' } @{$event[0]->{'headers'}};
    my @expected=$case eq 'response_only' ? ('existing=1') : ('a=1', $case eq 'identical' ? 'a=1' : 'b=2');
    is_deeply(\@cookie, \@expected, "$case cookies are preserved without duplication");
    my @ordinary=map { $_->[1] } grep { lc($_->[0]) eq 'x-test' } @{$event[0]->{'headers'}};
    is_deeply(\@ordinary, ['original'], "$case preserves ordinary header precedence");
}

done_testing();

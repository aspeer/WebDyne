use strict;
use warnings;
use Test::More;

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Middleware::Builder Future::AsyncAwait));
    plan skip_all => "Skipping PAGI request id test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use WebDyne::PAGI;
use PAGI::Middleware::Builder;
use Future;

#  $r->id reports the identifier PAGI's RequestId middleware assigns.
#
my $app_cr=builder {
    enable 'RequestId', trust_incoming => 1;
    WebDyne::PAGI->new(root => '.', static => 0)->to_app();
};
my ($id, @event);
{
    no warnings 'redefine';
    local *WebDyne::handler=sub {
        my ($class, $request_or)=@_;
        $id=$request_or->id();
        return 200;
    };
    $app_cr->(
        {type => 'http', method => 'GET', path => '/id.psp', query_string => '',
            headers => [['x-request-id', 'abc-123']]},
        sub { Future->done({type => 'http.request', body => '', more => 0}) },
        sub { push @event, shift(); Future->done() },
    )->get();
}
is($id, 'abc-123', 'id is the RequestId middleware identifier');
is($event[0]->{'status'}, 200, 'request completes');

done_testing();

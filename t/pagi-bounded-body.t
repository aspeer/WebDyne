use strict;
use warnings;
use Test::More;

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI bounded body test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use WebDyne::PAGI;
use Future;
use HTTP::Status qw(HTTP_OK);

#  A small configured bound exercises the same byte accounting cheaply.
#
local $WebDyne::PAGI::WEBDYNE_CGI_POST_MAX=16;
my $app_cr=WebDyne::PAGI->new(root => '.', static => 0)->to_app();
foreach my $case_ar (
    ['binary exact limit', 'application/octet-stream', "\x00\xff" x 8, undef, 200],
    ['raw over limit', 'application/octet-stream', 'x' x 17, undef, 413],
    ['underdeclared body', 'application/octet-stream', 'x' x 17, 1, 413],
    ['early rejection', 'application/json', '{}', 17, 413],
    ['JSON helper', 'application/json', '{"a":1}', undef, 200],
    ['urlencoded over limit', 'application/x-www-form-urlencoded', 'x' x 17, undef, 413],
    ['multipart over limit', 'multipart/form-data; boundary=b', 'x' x 17, undef, 413],
    ['empty body', 'application/octet-stream', '', undef, 200],
    ['zero byte', 'application/octet-stream', '0', undef, 200],
    ['disconnect', 'application/octet-stream', 'partial', undef, undef],
) {
    my ($name, $type, $body, $declared, $status)=@{$case_ar};
    my (@event, @receive);
    my $dispatched=0;
    my $scope_hr={type => 'http', method => 'POST', path => '/body.psp', headers => [['content-type', $type]]};
    push @{$scope_hr->{'headers'}}, ['content-length', $declared] if defined($declared);
    {
        no warnings 'redefine';
        local *WebDyne::handler=sub {
            my ($class, $request_or)=@_;
            $dispatched++;
            is($request_or->body(), $body, "$name exposes complete bytes");
            for (1..2) {
                my $body_fh=$request_or->body_handle();
                local $/;
                my $content=<$body_fh>;
                is(defined($content) ? $content : '', $body, "$name handle $_ starts at beginning");
                close($body_fh);
            }
            is($request_or->req()->body()->get(), $body, "$name preserves PAGI body helper");
            is_deeply($request_or->req()->json()->get(), {a => 1}, 'JSON helper remains usable') if $name eq 'JSON helper';
            return HTTP_OK;
        };
        my $future_or=$app_cr->($scope_hr,
            sub { my $receive_or=Future->new(); push @receive, $receive_or; return $receive_or },
            sub { push @event, shift(); Future->done() },
        );
        if ($name eq 'early rejection') {
            is(scalar(@receive), 0, 'oversize Content-Length rejected before receive');
        }
        else {
            ok(!$future_or->is_ready(), "$name waits for input");
            my $split=int(length($body)/2);
            $receive[0]->done({type => 'http.request', body => substr($body, 0, $split), more => 1});
            is($dispatched, 0, "$name does not dispatch partial body");
            is(scalar(@event), 0, "$name sends nothing before final chunk");
            $receive[1]->done($name eq 'disconnect'
                ? {type => 'http.disconnect'}
                : {type => 'http.request', body => substr($body, $split), more => 0});
        }
        $future_or->get();
    }
    if (defined($status)) {
        is($event[0]->{'status'}, $status, "$name response status");
        is($dispatched, $status == 200 ? 1 : 0, "$name dispatch count");
    }
    else {
        is($dispatched, 0, 'disconnect does not dispatch page');
        is(scalar(@event), 0, 'disconnect does not synthesize a response');
    }
}

done_testing();

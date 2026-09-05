use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping SSE body test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use WebDyne::PAGI;
use Future;

my $root_dn=tempdir(CLEANUP => 1);
open(my $page_fh, '>', File::Spec->catfile($root_dn, 'sse.psp')) || die $!;
print {$page_fh} <<'PAGE';
<start_html sse>
__PERL__
use Future::AsyncAwait;
async sub sse {
    my ($self, $param_hr)=@_;
    my $sse_or=$self->r()->sse();
    await $sse_or->start();
    await $sse_or->send_event(data => join(':', $param_hr->{'query'}, $param_hr->{'action'} || 'empty'));
    await $sse_or->close();
}
PAGE
close($page_fh);
my $app_cr=WebDyne::PAGI->new(root => $root_dn, static => 0)->to_app();
my $limit=$WebDyne::PAGI::WEBDYNE_CGI_POST_MAX;
foreach my $case_ar (
    ['GET', 'GET', '', '', undef, 'empty'],
    ['form', 'POST', 'application/x-www-form-urlencoded', 'action=advance', undef, 'advance'],
    ['exact limit', 'POST', 'application/x-www-form-urlencoded', 'action=' . ('a' x ($limit - 7)), undef, 'a' x ($limit - 7)],
    ['oversize', 'POST', 'application/x-www-form-urlencoded', 'a' x ($limit + 1), undef, undef],
    ['declared oversize', 'POST', 'application/x-www-form-urlencoded', '', $limit + 1, undef],
    ['disconnect', 'POST', 'application/x-www-form-urlencoded', 'action=advance', undef, undef],
) {
    my ($name, $method, $type, $body, $length, $expected)=@{$case_ar};
    my (@receive, @event);
    my $scope_hr={type => 'sse', method => $method, path => '/sse.psp', query_string => 'query=yes', headers => []};
    push @{$scope_hr->{'headers'}}, ['content-type', $type] if length($type);
    push @{$scope_hr->{'headers'}}, ['content-length', $length] if defined($length);
    my $future_or=$app_cr->($scope_hr,
        sub { my $receive_or=Future->new(); push @receive, $receive_or; return $receive_or },
        sub { push @event, shift(); Future->done() },
    );
    if ($name eq 'GET') {
        is(scalar(@receive), 0, 'GET starts without waiting for a body');
    }
    elsif ($name eq 'declared oversize') {
        is(scalar(@receive), 0, 'declared oversize rejected before reading');
    }
    else {
        ok(!$future_or->is_ready(), "$name waits for request body");
        my $split=int(length($body)/2);
        my $chunk_hr={type => 'sse.request', body => substr($body, 0, $split), more => 1};
        $receive[0]->done($chunk_hr);
        is($chunk_hr->{'type'}, 'sse.request', 'original event is not mutated');
        is(scalar(@event), 0, "$name sends nothing before final chunk");
        $receive[1]->done($name eq 'disconnect' ? {type => 'sse.disconnect'}
            : {type => 'sse.request', body => substr($body, $split), more => 0});
    }
    $future_or->get();
    if (defined($expected)) {
        is_deeply([map { $_->{'type'} } @event], [qw(sse.start sse.send sse.close)], "$name starts and closes stream");
        is($event[1]->{'data'}, "yes:$expected", "$name receives CGI body and query parameters");
    }
    elsif ($name eq 'disconnect') {
        is(scalar(@event), 0, 'disconnect sends no response');
    }
    else {
        is_deeply([map { $_->{'type'} } @event], [qw(sse.http.response.start sse.http.response.body)], "$name sends SSE denial response");
        is($event[0]->{'status'}, 413, "$name returns 413");
    }
}

done_testing();

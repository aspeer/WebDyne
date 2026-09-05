use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI form test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use WebDyne::PAGI;
use Future;

my $root_dn=tempdir(CLEANUP => 1);
my $page_fn=File::Spec->catfile($root_dn, 'form.psp');
open(my $page_fh, '>', $page_fn) || die $!;
print {$page_fh} <<'PAGE';
<perl handler="form_value" />
__PERL__
sub form_value {
    my $self=shift();
    my $value=$self->CGI()->param('action');
    $value=defined($value) ? $value : 'empty';
    my $result=join(':', 'form', $value, $self->r()->content_length());
    return \$result;
}
PAGE
close($page_fh);
my $app_cr=WebDyne::PAGI->new(root => $root_dn, static => 0)->to_app();
my $multipart="--boundary\r\nContent-Disposition: form-data; name=\"action\"\r\n\r\nadvance\r\n--boundary--\r\n";
foreach my $case_ar (
    ['urlencoded', 'application/x-www-form-urlencoded', 'action=advance', 'advance'],
    ['multipart', 'multipart/form-data; boundary=boundary', $multipart, 'advance'],
    ['empty urlencoded', 'application/x-www-form-urlencoded', '', 'empty'],
    ['empty multipart', 'multipart/form-data; boundary=boundary', '', 'empty'],
) {
    my ($name, $content_type, $body, $expected)=@{$case_ar};
    my $scope_hr={
        type => 'http', method => 'POST', path => '/form.psp', query_string => '',
        headers => [['content-type', $content_type]],
    };
    my @event;
    my @receive;
    my $future_or=$app_cr->($scope_hr,
        sub { my $receive_or=Future->new(); push @receive, $receive_or; return $receive_or },
        sub { push @event, shift(); Future->done() },
    );
    ok(!$future_or->is_ready(), "$name waits for body");
    my $split=int(length($body)/2);
    $receive[0]->done({type => 'http.request', body => substr($body, 0, $split), more => 1});
    ok(!$future_or->is_ready(), "$name waits for final chunk");
    is(scalar(@event), 0, "$name sends no response before body completes");
    $receive[1]->done({type => 'http.request', body => substr($body, $split), more => 0});
    $future_or->get();
    is($event[0]->{'status'}, 200, "$name returns HTTP 200");
    my $expected_text=join(':', 'form', $expected, length($body));
    like($event[1]->{'body'}, qr/\Q$expected_text\E/, "$name supplies parsed value and buffered length");
    is_deeply($scope_hr->{'headers'}, [['content-type', $content_type]], "$name preserves original headers");
}

my @event;
$app_cr->(
    {type => 'http', method => 'POST', path => '/form.psp', headers => [['content-type', 'multipart/form-data; boundary=boundary']]},
    sub { Future->done({type => 'http.request', body => 'x' x ($WebDyne::PAGI::WEBDYNE_CGI_POST_MAX + 1), more => 0}) },
    sub { push @event, shift(); Future->done() },
)->get();
is($event[0]->{'status'}, 413, 'multipart without Content-Length retains upload limit');

done_testing();

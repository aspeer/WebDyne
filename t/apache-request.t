use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Apache2::RequestRec; 1 } ||
        plan skip_all => 'Apache2::RequestRec unavailable';

    #  Exercise adapter methods without initializing server-only dispatch.
    #
    sub WebDyne::Request::Apache::method { return 'POST' }
}
use WebDyne::Request::Apache;

my $table_or=bless([
    ['Set-Cookie', 'a=1'], ['Set-Cookie', 'b=2'],
    ['X-Test', 'first'], ['X-Test', 'second'],
], 'ApacheReviewTable');
my $request_or=bless({table => $table_or}, 'ApacheReviewRequest');
my $adapter_or=WebDyne::Request::Apache->new($request_or);
foreach my $method (qw(headers_in headers_out)) {
    my $headers_or=$adapter_or->$method();
    is_deeply([$headers_or->header('Set-Cookie')], ['a=1', 'b=2'], "$method preserves cookies");
    is_deeply([$headers_or->header('X-Test')], ['first', 'second'], "$method preserves other repeated headers");
}
is(scalar(@{$table_or}), 4, 'snapshots leave native table unchanged');

foreach my $length (undef, 14) {
    my $adapter_or=body_request('action=advance', $length);
    is($adapter_or->body(), 'action=advance', 'body survives short reads with or without length');
    is($adapter_or->body(), 'action=advance', 'complete body is cached');
}
foreach my $body ('', '0', "\x00\xff") {
    is(body_request($body, undef)->body(), $body, 'empty, zero and binary bodies preserved');
}
foreach my $case_ar (
    ['abc', 6, 0, qr/incomplete/],
    ['', 'invalid', 0, qr/invalid/],
    ['', undef, 1, qr/unable to read/],
) {
    my ($body, $length, $fail, $error_qr)=@{$case_ar};
    my $adapter_or=body_request($body, $length, $fail);
    eval { $adapter_or->body() };
    like($@, $error_qr, 'invalid or incomplete body rejected');
    ok(!exists($adapter_or->{'body'}), 'failed read is not cached');
}

{
    local $WebDyne::Request::Apache::WEBDYNE_CGI_POST_MAX=16;
    foreach my $length (undef, 16) {
        is(body_request('x' x 16, $length)->body(), 'x' x 16, 'exact limit accepted');
    }
    foreach my $length (undef, 17) {
        my $adapter_or=body_request('x' x 17, $length);
        eval { $adapter_or->body() };
        like($@, qr/exceeds upload limit/, 'oversized body rejected');
        is($adapter_or->{'req'}{'reads'}, 0, 'declared oversize rejected before reading') if defined($length);
        foreach my $method (qw(READ READLINE)) {
            eval {
                my $input_or=WebDyne::Request::Apache::Body->TIEHANDLE(body_request('x' x 17, $length)->{'req'});
                my $chunk;
                while ($method eq 'READ' ? $input_or->READ($chunk, 8) : defined($input_or->READLINE())) {}
            };
            like($@, qr/exceeds upload limit/, "$method enforces body limit");
        }
    }
}

require WebDyne::CGI::Simple;
foreach my $length (undef, 14) {
    local %ENV=%ENV;
    delete @ENV{qw(CONTENT_LENGTH CONTENT_TYPE REQUEST_METHOD QUERY_STRING)};
    my $adapter_or=body_request('action=advance', $length);
    $adapter_or->{'req'}{'headers'}{'content-type'}='application/x-www-form-urlencoded; charset=UTF-8';
    my $cgi_or=WebDyne::CGI::Simple->new($adapter_or);
    is($cgi_or->param('action'), 'advance', 'URL-encoded form parsed with or without length');
}
my $multipart="--boundary\r\nContent-Disposition: form-data; name=\"action\"\r\n\r\nadvance\r\n--boundary--\r\n";
foreach my $length (undef, length($multipart)) {
    local %ENV=%ENV;
    delete @ENV{qw(CONTENT_LENGTH CONTENT_TYPE REQUEST_METHOD QUERY_STRING)};
    my $adapter_or=body_request($multipart, $length);
    $adapter_or->{'req'}{'headers'}{'content-type'}='multipart/form-data; boundary=boundary';
    $adapter_or->{'req'}{'headers'}{'Content-Type'}=$adapter_or->{'req'}{'headers'}{'content-type'};
    my $cgi_or=WebDyne::CGI::Simple->new($adapter_or);
    is($cgi_or->param('action'), 'advance', 'multipart form parsed with or without length');
}

done_testing();


sub body_request {
    my ($body, $length, $fail)=@_;
    my $request_or=bless({
        body => $body, headers => {'Content-Length' => $length}, fail => $fail, reads => 0,
    }, 'ApacheBodyRequest');
    return ApacheBodyAdapter->new($request_or);
}


package ApacheBodyAdapter;
use parent 'WebDyne::Request::Apache';
sub args { return '' }
sub input { return shift()->body_handle() }


package ApacheBodyRequest;
sub headers_in { return shift()->{'headers'} }
sub read {
    my ($self, undef, $length)=@_;
    $self->{'reads'}++;
    return undef if $self->{'fail'};
    $length=3 if $length > 3;
    $_[1]=substr($self->{'body'}, 0, $length, '');
    return length($_[1]);
}


package ApacheReviewRequest;

sub headers_in { return shift()->{'table'} }
sub headers_out { return shift()->{'table'} }


package ApacheReviewTable;

sub do {
    my ($self, $callback_cr)=@_;
    foreach my $pair_ar (@{$self}) {
        $callback_cr->(@{$pair_ar}) || last;
    }
    return 1;
}

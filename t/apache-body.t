use strict;
use warnings;
use Test::More;
use lib 't';
BEGIN {
    require apache_harness_helper;
    my @missing=apache_harness_helper::apache_prereq_missing();
    plan skip_all => join(', ', @missing) if @missing;
    plan skip_all => 'Apache tests cannot run as root' unless $>;
}
use Apache::TestRequest;
use File::Temp qw(tempdir);
use File::Basename qw(basename);
use IO::Socket::INET;

my $page_dn=tempdir('apache-body-XXXX', DIR => 't', CLEANUP => 1);
open(my $page_fh, '>', "$page_dn/form.psp") || die $!;
print {$page_fh} <<'PAGE';
<perl handler="form" />
__PERL__
sub form {
    my $self=shift();
    my $result='field:'.($self->CGI()->param('action') || 'empty');
    return \$result;
}
PAGE
close($page_fh);

my $runner_or;
my $ok=eval {
    $runner_or=apache_harness_helper::startup();
    foreach my $case_ar (
        ['application/x-www-form-urlencoded; charset=UTF-8', 'action=advance'],
        ['multipart/form-data; boundary=boundary',
            "--boundary\r\nContent-Disposition: form-data; name=\"action\"\r\n\r\nadvance\r\n--boundary--\r\n"],
    ) {
        my ($type, $body)=@{$case_ar};
        foreach my $chunked (0, 1) {
            my $response=post_body($type, $body, $chunked);
            like($response, qr{\AHTTP/1\.[01] 200 }, 'Apache accepts form submission');
            like($response, qr/field:advance/, $chunked ? 'chunked form decoded without Content-Length' : 'form with Content-Length decoded');
        }
    }
    foreach my $chunked (0, 1) {
        my $response=post_body('application/x-www-form-urlencoded', 'x' x (512*1024+1), $chunked);
        like($response, qr{\AHTTP/1\.[01] 500 }, 'uncaught defensive body exception fails the request');
        unlike($response, qr/field:/, 'oversized body does not reach form handler result');
    }
    1;
};
my $error=$@;
apache_harness_helper::shutdown($runner_or) if $runner_or;
die $error unless $ok;
done_testing();


sub post_body {
    my ($type, $body, $chunked)=@_;
    my $host=Apache::TestRequest::hostport();
    my $socket_or=IO::Socket::INET->new(PeerAddr => $host, Timeout => 10) || die $!;
    my $path='/'.basename($page_dn).'/form.psp';
    my $framing=$chunked ? "Transfer-Encoding: chunked\r\n" : 'Content-Length: '.length($body)."\r\n";
    print {$socket_or} "POST $path HTTP/1.1\r\nHost: $host\r\nConnection: close\r\nContent-Type: $type\r\n$framing\r\n";
    print {$socket_or} $chunked ? sprintf("%x\r\n%s\r\n0\r\n\r\n", length($body), $body) : $body;
    local $/;
    my $response=<$socket_or>;
    close($socket_or);
    return $response;
}

use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
BEGIN { $ENV{'WEBDYNE_CONF'}='.'; $ENV{'WEBDYNE_ERROR_TEXT'}=1 }
use WebDyne::PSGI;
use IO::String;

my $root_dn=tempdir(CLEANUP => 1);
my %page=(
    'form.psp' => <<'PAGE',
<perl handler="form" />
__PERL__
sub form {
    my $self=shift();
    my $value=$self->CGI()->param('action');
    my $result='field:'.(defined($value) ? $value : 'empty');
    return \$result;
}
PAGE
    'api.psp' => <<'PAGE',
<api handler="form" pattern="/form">
__PERL__
sub form {
    my $self=shift();
    return {action => scalar($self->CGI()->param('action'))};
}
PAGE
);
foreach my $name (keys %page) {
    open(my $page_fh, '>', File::Spec->catfile($root_dn, $name)) || die $!;
    print {$page_fh} $page{$name};
    close($page_fh);
}
my $app_cr=WebDyne::PSGI->new(root => $root_dn, static => 0)->to_app();
foreach my $case_ar (
    ['short reads', 14, '/form.psp', 'field:advance'],
    ['missing length', undef, '/form.psp', 'field:advance'],
    ['API redispatch', undef, '/api/form', '"action":"advance"'],
) {
    my ($name, $length, $path, $expected)=@{$case_ar};
    my $input_or=bless({body => 'action=advance', reads => 0}, 'PSGIBodyInput');
    my $env_hr=environment($input_or, $length, $path);
    my $response_ar=$app_cr->($env_hr);
    is($response_ar->[0], 200, "$name succeeds");
    like(join('', @{$response_ar->[2]}), qr/\Q$expected\E/, "$name preserves body fields");
    cmp_ok($input_or->{'reads'}, '>', 1, "$name handles multiple reads");
    is(exists($env_hr->{'CONTENT_LENGTH'}), defined($length) ? 1 : '', "$name leaves original length metadata unchanged");
}
my $limit=$WebDyne::Request::PSGI::WEBDYNE_CGI_POST_MAX;
foreach my $case_ar (
    ['declared oversize', '', $limit+1, 413, 0],
    ['actual oversize', 'x' x ($limit+1), undef, 413, undef],
    ['truncated', 'abc', 6, 400, undef],
    ['invalid length', '', 'invalid', 400, 0],
    ['read failure', '', undef, 400, undef],
) {
    my ($name, $body, $length, $status, $reads)=@{$case_ar};
    my $input_or=bless({body => $body, reads => 0, chunk => 8192, fail => $name eq 'read failure'}, 'PSGIBodyInput');
    my $response_ar=$app_cr->(environment($input_or, $length, '/form.psp'));
    is($response_ar->[0], $status, "$name rejected");
    is($input_or->{'reads'}, $reads, "$name rejected before reading") if defined($reads);
}
foreach my $body ('', '0', "\x00\xff", 'x' x $limit) {
    my $env_hr=environment(IO::String->new($body), undef, '/form.psp');
    my $request_or=WebDyne::Request::PSGI->new(env => $env_hr, req => Plack::Request->new($env_hr), filename => 'unused');
    is($request_or->body(), $body, 'body reader preserves empty, zero, binary and exact-limit data');
    is($request_or->body(), $body, 'body reader caches complete data');
}
my $multipart="--b\r\nContent-Disposition: form-data; name=\"action\"\r\n\r\nadvance\r\n--b--\r\n";
my $env_hr=environment(IO::String->new($multipart), undef, '/form.psp');
$env_hr->{'CONTENT_TYPE'}='multipart/form-data; boundary=b';
my $response_ar=$app_cr->($env_hr);
is($response_ar->[0], 200, 'multipart without length succeeds');
like(join('', @{$response_ar->[2]}), qr/field:advance/, 'multipart without length reaches CGI');
done_testing();

sub environment {
    my ($input_or, $length, $path)=@_;
    my $env_hr={REQUEST_METHOD => 'POST', PATH_INFO => $path, SCRIPT_NAME => '', QUERY_STRING => '',
        CONTENT_TYPE => 'application/x-www-form-urlencoded', 'psgi.input' => $input_or};
    $env_hr->{'CONTENT_LENGTH'}=$length if defined($length);
    return $env_hr;
}

package PSGIBodyInput;
sub read {
    my $self=shift();
    $self->{'reads'}++;
    return undef if $self->{'fail'};
    my $length=$self->{'chunk'} || 3;
    $length=$_[1] if $_[1] < $length;
    $_[0]=substr($self->{'body'}, 0, $length, '');
    return length($_[0]);
}

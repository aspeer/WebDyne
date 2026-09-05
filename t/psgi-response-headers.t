use strict;
use warnings;
use Test::More;
BEGIN {
    my @missing;
    foreach my $module (qw(Plack::Builder Plack::Request Plack::Response)) {
        eval "require $module; 1" || push @missing, $module;
    }
    plan skip_all => 'Skipping PSGI tests: missing '.join(', ', @missing) if @missing;
    $ENV{'WEBDYNE_CONF'}='.';
}
use WebDyne::PSGI;
use IO::String;

my $app_cr=WebDyne::PSGI->new(root => '.', static => 0)->to_app();
my $response_ar;
{
    no warnings 'redefine';
    local *WebDyne::handler=sub {
        my ($class, $request_or)=@_;
        $request_or->headers_out()->push_header('Set-Cookie' => 'a=1');
        $request_or->headers_out()->push_header('Set-Cookie' => 'b=2');
        $request_or->headers_out()->push_header('X-Test' => 'first');
        $request_or->headers_out()->push_header('X-Test' => 'second');
        $request_or->status(200);
        return 200;
    };
    $response_ar=$app_cr->({REQUEST_METHOD => 'GET', PATH_INFO => '/headers.psp',
        SCRIPT_NAME => '', 'psgi.input' => IO::String->new('')});
}
my %values;
my $headers_ar=$response_ar->[1];
for (my $ix=0; $ix<@{$headers_ar}; $ix+=2) {
    ok(!ref($headers_ar->[$ix+1]), 'PSGI header value is scalar');
    push @{$values{lc($headers_ar->[$ix])}}, $headers_ar->[$ix+1];
}
is_deeply($values{'set-cookie'}, ['a=1', 'b=2'], 'cookies emitted separately and in order');
is_deeply($values{'x-test'}, ['first', 'second'], 'other repeated headers preserved');
done_testing();

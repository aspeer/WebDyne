use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    plan skip_all => "Skipping PAGI mount test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use WebDyne::PAGI;
use Future;
use JSON qw(decode_json);

my $root_dn=tempdir(CLEANUP => 1);
my %page=(
    'index.psp' => '<p>mount index</p>',
    'page.psp' => <<'PAGE',
<perl handler="paths" />
__PERL__
sub paths {
    my $self=shift();
    my $request_or=$self->r();
    my $text=join('|', $request_or->script_name(), $request_or->path_info(),
        $request_or->path(), $ENV{'SCRIPT_NAME'}, $ENV{'PATH_INFO'});
    return \$text;
}
PAGE
    'api.psp' => <<'PAGE',
<api handler="hello" pattern="/hello/{name}">
__PERL__
sub hello {
    my ($self, $match_hr)=@_;
    return {name => $match_hr->{'name'}, mount => $self->r()->script_name()};
}
PAGE
);
foreach my $name (keys %page) {
    open(my $page_fh, '>', File::Spec->catfile($root_dn, $name)) || die $!;
    print {$page_fh} $page{$name};
    close($page_fh);
}
my $app_cr=WebDyne::PAGI->new(root => $root_dn, index => 'index.psp', static => 0)->to_app();
foreach my $mount ('', '/mount', '/nested/mount') {
    my $path="$mount/page.psp";
    my $event_ar=request($app_cr, $mount, $path);
    is($event_ar->[0]->{'status'}, 200, "$mount page resolves");
    my $expected=join('|', $mount, '/page.psp', $path, $mount, '/page.psp');
    like($event_ar->[1]->{'body'}, qr/\Q$expected\E/, "$mount exposes CGI and request paths");
    foreach my $suffix ('/api/hello/world') {
        my $api_ar=request($app_cr, $mount, "$mount$suffix");
        is($api_ar->[0]->{'status'}, 200, "$mount$suffix resolves");
        is_deeply(decode_json($api_ar->[1]->{'body'}), {name => 'world', mount => $mount}, 'mounted API dispatches route');
    }
    foreach my $suffix ('', '/') {
        my $index_ar=request($app_cr, $mount, "$mount$suffix");
        is($index_ar->[0]->{'status'}, 200, 'mount root resolves index');
        like($index_ar->[1]->{'body'}, qr/mount index/, 'index content rendered');
    }
}
is(WebDyne::Request::PAGI::scope_path({root_path => '/app', path => '/apple/page.psp'}), '/apple/page.psp', 'mount match requires path boundary');
is(WebDyne::Request::PAGI::scope_path({root_path => '/app/', path => '/app/page.psp'}), '/page.psp', 'trailing mount slash supported');
is(WebDyne::Request::PAGI::scope_path({root_path => '/', path => '/page.psp'}), '/page.psp', 'root mount preserves leading slash');

done_testing();

sub request {
    my ($app_cr, $mount, $path)=@_;
    my $scope_hr={type => 'http', method => 'GET', path => $path, root_path => $mount, query_string => '', headers => []};
    my @event;
    $app_cr->($scope_hr,
        sub { Future->done({type => 'http.request', body => '', more => 0}) },
        sub { push @event, shift(); Future->done() },
    )->get();
    is($scope_hr->{'path'}, $path, 'original scope path preserved');
    return \@event;
}

#  Pragma
#
use strict;
use warnings;


#  Test Harness
#
use Test::More;


#  Skip test if PSGI dependencies are unavailable
#
BEGIN {
    my @missing;
    for my $m (qw(Plack::Test Plack::Request Plack::Response)) {
        eval "require $m; 1" or push @missing, $m;
    }
    plan skip_all => "Skipping PSGI API test: missing " . join(", ", @missing)
        if @missing;
}


#  Skip any local config
#
BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
}


#  Modules we need
#
use FindBin qw($RealBin);
use File::Spec;
use File::Temp qw(tempdir);
use IO::File;
use File::Path qw(make_path);
use Plack::Test;
use HTTP::Request::Common qw(GET);
use lib "$RealBin/../lib";


#  Load WebDyne modules we need
#
use WebDyne::PSGI;


#  Run tests
#
ok(${&main() || die 'main failed'} || 0);
done_testing();


#======================================================================================================================


sub main {

    my $root_dn=tempdir(CLEANUP => 1);
    my $base_dn=tempdir(CLEANUP => 1);
    my $traversal_root_dn=File::Spec->catdir($base_dn, 'htdocs');
    make_path($traversal_root_dn);

    my %page=(
        'api.psp' => <<'EOF',
<api handler=uppercase pattern="/uppercase/{user}/:id">
__PERL__
sub uppercase {
    my ($self, $match)=@_;
    return { user => uc($match->{user}), id => $match->{id} };
}
EOF
        'example/route.psp' => <<'EOF',
<api handler=route pattern="/{user}">
__PERL__
sub route {
    my ($self, $match)=@_;
    return { user => uc($match->{user}) };
}
EOF
        'example/api.psp' => <<'EOF',
<api handler=uppercase pattern="/uppercase/{user}/:id">
<api handler=lowercase pattern="/lowercase/{user}/:id">
__PERL__
sub uppercase {
    my ($self, $match)=@_;
    return { user => uc($match->{user}), id => $match->{id} };
}
sub lowercase {
    my ($self, $match)=@_;
    return { user => lc($match->{user}), id => $match->{id} };
}
EOF
        'normal.psp' => '<start_html>normal PSGI page</start_html>',
    );

    for my $relative (keys %page) {
        my $filename=File::Spec->catfile($root_dn, split m{/}, $relative);
        ok(write_file($filename, $page{$relative}), "create temporary page $relative");
    }

    ok(my $psgi_or=WebDyne::PSGI->new(root => $root_dn), 'build PSGI application');
    ok(my $app_cr=$psgi_or->to_app(), 'build PSGI app');
    ok(my $test_or=Plack::Test->create($app_cr), 'create PSGI test client');

    my $res=$test_or->request(GET('/api/uppercase/bob/42'));
    is($res->code(), 200, 'root API PSP returns HTTP 200');
    like($res->decoded_content() || '', qr/"user"\s*:\s*"BOB"/, 'root API route receives user');
    like($res->decoded_content() || '', qr/"id"\s*:\s*"42"/, 'root API route receives id');
    ok($psgi_or->{'API_fn'}{File::Spec->catfile($root_dn, 'api.psp')},
        'root API PSP is cached after discovery');

    $res=$test_or->request(GET('/example/route/bob'));
    is($res->code(), 200, 'nested API PSP returns HTTP 200');
    like($res->decoded_content() || '', qr/"user"\s*:\s*"BOB"/, 'nested API local route receives user');

    $res=$test_or->request(GET('/example/api/uppercase/bob/42'));
    is($res->code(), 200, 'subdirectory API PSP with local route returns HTTP 200');
    like($res->decoded_content() || '', qr/"user"\s*:\s*"BOB"/,
        'subdirectory API PSP local route receives user');
    like($res->decoded_content() || '', qr/"id"\s*:\s*"42"/,
        'subdirectory API PSP local route receives id');

    $res=$test_or->request(GET('/example/api/lowercase/BOB/42'));
    is($res->code(), 200, 'subdirectory API PSP second local route returns HTTP 200');
    like($res->decoded_content() || '', qr/"user"\s*:\s*"bob"/,
        'subdirectory API PSP second local route receives user');

    $res=$test_or->request(GET('/normal.psp'));
    is($res->code(), 200, 'normal PSP request remains available');
    like($res->decoded_content() || '', qr/normal PSGI page/, 'normal PSP response is rendered');

    $res=$test_or->request(GET('/missing/path'));
    is($res->code(), 404, 'unmatched request remains not found');

    write_file(
        File::Spec->catfile($traversal_root_dn, 'index.psp'),
        '<html><? "INSIDE-" . 6*7 ?></html>'
    );
    write_file(
        File::Spec->catfile($base_dn, 'private.psp'),
        '<html><? "OUTSIDE-" . 6*7 ?></html>'
    );

    ok(my $traversal_app_cr=WebDyne::PSGI->new(root => $traversal_root_dn)->to_app(),
        'build PSGI traversal regression application');
    ok(my $traversal_test_or=Plack::Test->create($traversal_app_cr),
        'create PSGI traversal regression client');

    $res=$traversal_test_or->request(GET('/index.psp'));
    is($res->code(), 200, 'traversal regression positive control returns HTTP 200');
    like($res->decoded_content() || '', qr/INSIDE-42/,
        'traversal regression positive control executes in-root PSP');

    $res=$traversal_test_or->request(GET('/private'));
    is($res->code(), 404, 'outside PSP is not reachable without traversal');
    unlike($res->decoded_content() || '', qr/OUTSIDE-42/,
        'outside PSP does not execute without traversal');

    $res=$traversal_test_or->request(GET('/../private'));
    is($res->code(), 404, 'PSGI API fallback rejects parent-directory traversal');
    unlike($res->decoded_content() || '', qr/OUTSIDE-42/,
        'PSGI API fallback does not execute out-of-root PSP through traversal');

    return \1;
}


sub write_file {

    my ($fn, $content)=@_;
    my ($volume, $directory)=File::Spec->splitpath($fn);
    make_path($directory) if length($directory) && !-d $directory;
    my $fh=IO::File->new($fn, O_WRONLY|O_CREAT|O_TRUNC) ||
        die "unable to write $fn, $!";
    print {$fh} $content;
    $fh->close();
    return $fn;

}

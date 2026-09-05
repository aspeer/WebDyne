use strict qw(vars);
use warnings;
use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use bin_helper qw(run_cmd write_file);
use File::Temp qw(tempdir);
use File::Spec;
use IO::String;

my $tmp_dn=tempdir(CLEANUP => 1);
my $block_fn=File::Spec->catfile($tmp_dn, 'NoWebRuntime.pm');
write_file($block_fn, <<'END_BLOCK');
package NoWebRuntime;
BEGIN {
    unshift @INC, sub {
        die "optional runtime blocked: $_[1]\n"
            if $_[1]=~m{^(?:Plack|PAGI)(?:/|\.pm$)};
        return;
    };
}
1;
END_BLOCK

#  Child Perl processes, including wdlint syntax checks, must see the same
#  missing-runtime environment. Other installed dependencies stay available.
#
{
    local $ENV{'PERL5OPT'}="-I$tmp_dn -MNoWebRuntime";
    local $ENV{'WEBDYNE_CONF'}='.';
    foreach my $module (qw(Plack::Request PAGI::Request)) {
        my ($out, $err, $rc)=run_cmd($^X, '-e', "require $module");
        isnt($rc, 0, "$module is blocked in child processes");
        like($err, qr/optional runtime blocked/, 'blocker caused the load failure');
    }

    my $source_fn=File::Spec->catfile($tmp_dn, 'simple.psp');
    write_file($source_fn, '<html><body>Result: <? 6 * 7 ?></body></html>');
    foreach my $tool (qw(wdrender wdcompile wdlint)) {
        my @opt=$tool eq 'wdrender' ? ('--fake', '--raw', '--no-conf') : ();
        my ($out, $err, $rc)=run_cmd($^X, '-Ilib', "bin/$tool", @opt, $source_fn);
        is($rc, 0, "$tool works without optional runtimes");
        unlike($out.$err, qr/optional runtime blocked/, "$tool does not load optional runtimes");
        like($out, qr/Result: 42/, 'standalone Perl expression renders') if $tool eq 'wdrender';
    }

    my $asset_fn=File::Spec->catfile($tmp_dn, 'asset.txt');
    write_file($asset_fn, 'standalone static content');
    write_file($source_fn, '<perl>my $self=shift(); $self->subrequest({file=>"asset.txt"}); return q();</perl>');
    my ($out, $err, $rc)=run_cmd($^X, '-Ilib', 'bin/wdrender', '--fake', '--raw', '--no-conf', $source_fn);
    is($rc, 0, 'static subrequest render exits successfully');
    like($out, qr/standalone static content/, 'static subrequest renders without Plack');
    unlike($out.$err, qr/optional runtime blocked/, 'static subrequest does not load optional runtimes');
}

#  Exercise the responder itself with optional modules blocked, checking
#  exact output rather than relying on the renderer exit status alone.
#
{
    local @INC=(sub {
        die "optional runtime blocked: $_[1]\n" if $_[1]=~m{^(?:Plack|PAGI)(?:/|\.pm$)};
        return;
    }, @INC);
    require WebDyne::Request::Fake;
    foreach my $case ([ 'empty.txt', '', 'text/plain' ],
        [ 'binary.png', pack('C*', 0..255), 'image/png' ],
        [ 'large.txt', 'x' x 20000, 'text/plain' ]) {
        my ($name, $bytes, $type)=@{$case};
        my $fn=File::Spec->catfile($tmp_dn, $name);
        open(my $fh, '>', $fn) || die $!;
        binmode($fh);
        print {$fh} $bytes;
        close($fh) || die $!;
        my $body='';
        my $output_fh=IO::String->new($body);
        my $r=WebDyne::Request::Fake->new(filename=>$fn, select=>$output_fh, noheader=>1);
        my $child=$r->lookup_file($fn);
        isa_ok($child, 'WebDyne::Request::PSGI::Static');
        is($child->run(), 200, "$name status");
        is($body, $bytes, "$name exact bytes");
        is($r->headers_out->{'Content-Length'}, length($bytes), "$name length");
        is($r->headers_out->{'Content-Type'}, $type, "$name content type");
    }
    my $fn=File::Spec->catfile($tmp_dn, 'missing.txt');
    my $r=WebDyne::Request::Fake->new(filename=>$fn);
    my $warning='';
    local $SIG{'__WARN__'}=sub { $warning.=shift() };
    is($r->lookup_file($fn)->run(), 404, 'missing static file returns 404');
    like($warning, qr/not found/, 'missing file reports the failure');
}

#  The same helper must still work when reached through real runtime adapters.
#
foreach my $backend (qw(psgi pagi)) {
    SKIP: {
        my $available=$backend eq 'psgi'
            ? eval { require WebDyne::PSGI; require Plack::Test; 1 }
            : eval { require WebDyne::PAGI; require PAGI::Test::Client; 1 };
        skip "$backend dependencies unavailable: $@", 3 unless $available;
        my $source_fn=File::Spec->catfile($tmp_dn, 'simple.psp');
        my ($out, $err, $rc)=run_cmd($^X, '-Ilib', 'bin/wdrender', '--raw',
            '--no-conf', "--request=$backend", $source_fn);
        is($rc, 0, "$backend static subrequest exits successfully");
        like($out, qr/standalone static content/, "$backend parent receives static content");
        is($err, '', "$backend static subrequest writes no stderr");
    }
}

done_testing();

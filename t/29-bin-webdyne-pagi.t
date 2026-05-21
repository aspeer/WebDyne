use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_module);
use File::Temp qw(tempdir);
use File::Spec;

my $script=File::Spec->catfile('bin', 'webdyne.pagi');
ok(-f $script, 'webdyne.pagi script exists');

BEGIN {
    my @missing;
    for my $m (qw(PAGI PAGI::Middleware::Builder PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait)) {
        eval "require $m; 1" or push @missing, $m;
    }
    @missing and plan skip_all => 'Skipping webdyne.pagi script test: missing ' . join(', ', @missing);
}

my $stub_dn=tempdir(CLEANUP => 1);
write_module($stub_dn, 'PAGI::Runner', <<'END_MODULE');
package PAGI::Runner;
use strict;
use warnings;
sub new { bless {}, shift }
sub parse_options {
    my ($self, @argv)=@_;
    $self->{argv}=\@argv;
    return $self;
}
sub run {
    my $self=shift;
    my $app=PAGI::Runner::load_app();
    print "args=" . join(' ', @{$self->{argv} || []}) . "\n";
    print "app=" . ref($app) . "\n";
    return 0;
}
1;
END_MODULE

my $tmp_dn=tempdir(CLEANUP => 1);
my ($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--noindex', '--nostatic', '--argv', '--port 6011 --workers 2',
    $tmp_dn,
);
is($rc, 0, 'webdyne.pagi exits cleanly through stubbed runner');
like($stdout, qr/args=.*--port 6011 .*--workers 2 .*--host 0\.0\.0\.0/, 'webdyne.pagi prepends argv options and default host');
like($stdout, qr/app=CODE/, 'webdyne.pagi passes a built app coderef to PAGI::Runner');
is($stderr, '', 'webdyne.pagi stubbed run writes no stderr');

done_testing();

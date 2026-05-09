use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_module write_file);
use File::Temp qw(tempdir tempfile);
use File::Spec;

my $script=File::Spec->catfile('bin', 'webdyne.psgi');
ok(-f $script, 'webdyne.psgi script exists');

my $stub_dn=tempdir(CLEANUP => 1);
write_module($stub_dn, 'Plack::Runner', <<'END_MODULE');
package Plack::Runner;
use strict;
use warnings;
sub new { bless {}, shift }
sub parse_options {
    my ($self, @argv)=@_;
    $self->{argv}=\@argv;
    return $self;
}
sub run {
    my ($self, $app)=@_;
    open(my $input_fh, '<', '/dev/null') || die $!;
    my $res=$app->({
        REQUEST_METHOD     => 'GET',
        PATH_INFO          => '/app.psp',
        SCRIPT_NAME        => '',
        SERVER_NAME        => 'localhost',
        SERVER_PORT        => 80,
        'psgi.version'     => [1, 1],
        'psgi.url_scheme'  => 'http',
        'psgi.input'       => $input_fh,
        'psgi.errors'      => *STDERR,
        'psgi.multithread' => 0,
        'psgi.multiprocess'=> 0,
        'psgi.run_once'    => 1,
        'psgi.streaming'   => 0,
        'psgi.nonblocking' => 0,
    });
    print "args=" . join(' ', @{$self->{argv} || []}) . "\n";
    print "status=$res->[0]\n";
    print "body=" . join('', @{$res->[2]}) . "\n";
    return 0;
}
1;
END_MODULE

my $tmp_dn=tempdir(CLEANUP => 1);
write_file("$tmp_dn/app.psp", "<start_html>psgi\n");

my ($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--noindex', '--nostatic', '--argv', '--port 6021',
    $tmp_dn,
);
is($rc, 0, 'webdyne.psgi exits cleanly through stubbed runner');
like($stdout, qr/args=.*--port 6021/, 'webdyne.psgi forwards argv options to Plack::Runner');
like($stdout, qr/status=200/, 'webdyne.psgi built app serves request through stubbed runner');
like($stdout, qr/body=.*psgi/s, 'webdyne.psgi built app returns rendered body');
is($stderr, '', 'webdyne.psgi stubbed run writes no stderr');

done_testing();

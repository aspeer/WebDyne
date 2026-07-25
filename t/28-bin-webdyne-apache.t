use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file write_module);
use File::Temp qw(tempdir);
use File::Spec;

my $script=File::Spec->catfile('bin', 'webdyne.apache');
ok(-f $script, 'webdyne.apache script exists');

my $stub_dn=tempdir(CLEANUP => 1);
write_module($stub_dn, 'Apache2::Build', "package Apache2::Build; 1;\n");
write_module($stub_dn, 'Apache::Test', "package Apache::Test; 1;\n");
write_module($stub_dn, 'Module::CoreList', "package Module::CoreList; 1;\n");
write_module($stub_dn, 'Apache::TestConfig', "package Apache::TestConfig; 1;\n");
write_module($stub_dn, 'Apache::TestRunPerl', <<'END_MODULE');
package Apache::TestRunPerl;
use strict;
use warnings;
sub new { bless {}, shift }
sub run {
    my ($self, @argv)=@_;
    print join("\n", @argv), "\n";
    CORE::exit 0;
}
1;
END_MODULE

my $tmp_dn=tempdir(CLEANUP => 1);
my $source_fn="$tmp_dn/app.psp";
write_file($source_fn, "<start_html>apache\n");

my ($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--port', '5123', '--noindex', $source_fn,
);
is($rc, 0, 'webdyne.apache exits cleanly through stubbed pause');
like($stdout, qr/-port\n5123/, 'webdyne.apache forwards requested port to Apache runner');
like($stdout, qr/PerlSetEnv DOCUMENT_ROOT \Q$source_fn\E/, 'webdyne.apache preserves file root as DOCUMENT_ROOT in postamble');
like($stdout, qr/Alias \/index\.psp/, 'webdyne.apache emits index alias postamble for file-root startup');
is($stderr, '', 'webdyne.apache stubbed run writes no stderr');
#diag($stderr);
done_testing();

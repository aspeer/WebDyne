use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file);
use File::Temp qw(tempdir);
use File::Spec;

my $script=File::Spec->catfile('bin', 'wdlint');
ok(-f $script, 'wdlint script exists');

my $syntax_cmd="perl -c -Ilib $script";
my ($compile_out, $compile_err, $compile_rc)=run_cmd($^X, '-c', '-Ilib', $script);
is($compile_rc, 0, 'wdlint script itself compiles cleanly');
like($compile_out . $compile_err, qr/syntax OK/, 'wdlint syntax check reports OK');

my $tmp_dn=tempdir(CLEANUP => 1);
my $good_fn="$tmp_dn/good.psp";
my $bad_fn="$tmp_dn/bad.psp";
my $bad_inline_fn="$tmp_dn/bad_inline.psp";
my $bad_pi_fn="$tmp_dn/bad_pi.psp";
my $bad_subst_fn="$tmp_dn/bad_subst.psp";
my $bad_multi_fn="$tmp_dn/bad_multi.psp";
my $good_lookup_fn="$tmp_dn/good_lookup.psp";

write_file($good_fn, <<'END_PSP');
<start_html>
Hello
__PERL__
sub hello {
    return 1;
}
END_PSP

write_file($bad_fn, <<'END_PSP');
<start_html>
Hello
__PERL__
sub hello {
    my 2 == 1;
}
END_PSP

write_file($bad_inline_fn, <<'END_PSP');
<start_html>
<perl>
my 2 == 1;
</perl>
END_PSP

write_file($bad_pi_fn, <<'END_PSP');
<start_html>
<? my 2 == 1 ?>
END_PSP

write_file($bad_subst_fn, <<'END_PSP');
<start_html>
!{! my 2 == 1 !}
END_PSP

write_file($bad_multi_fn, <<'END_PSP');
<start_html>
<? my 2 == 1 ?>
!{! my 3 == 4 !}
END_PSP

write_file($good_lookup_fn, <<'END_PSP');
<start_html>
+{not_perl}
END_PSP

my ($good_out, $good_err, $good_rc)=run_cmd($^X, '-Ilib', $script, $good_fn);
is($good_rc, 0, 'wdlint exits cleanly on valid __PERL__ section');
like($good_out, qr/\Q$good_fn\E syntax OK/, 'wdlint reports syntax OK for valid file');
is($good_err, '', 'wdlint writes no stderr for valid file');

my ($bad_out, $bad_err, $bad_rc)=run_cmd($^X, '-Ilib', $script, $bad_fn);
ok($bad_rc != 0, 'wdlint exits non-zero on invalid __PERL__ section');
like($bad_out, qr/\Q$bad_fn\E/, 'wdlint reports the original source filename on error');
like($bad_out, qr/syntax error|had compilation errors/, 'wdlint reports Perl syntax failure');
is($bad_err, '', 'wdlint writes no stderr for invalid file');

my ($bad_inline_out, $bad_inline_err, $bad_inline_rc)=run_cmd($^X, '-Ilib', $script, $bad_inline_fn);
ok($bad_inline_rc != 0, 'wdlint exits non-zero on invalid <perl> section');
like($bad_inline_out, qr/\Q$bad_inline_fn\E/, 'wdlint reports inline perl source filename on error');
like($bad_inline_out, qr/syntax error|had compilation errors/, 'wdlint reports inline Perl syntax failure');
is($bad_inline_err, '', 'wdlint writes no stderr for invalid inline perl file');

my ($bad_pi_out, $bad_pi_err, $bad_pi_rc)=run_cmd($^X, '-Ilib', $script, $bad_pi_fn);
ok($bad_pi_rc != 0, 'wdlint exits non-zero on invalid processing instruction');
like($bad_pi_out, qr/\Q$bad_pi_fn\E/, 'wdlint reports processing instruction source filename on error');
like($bad_pi_out, qr/syntax error|had compilation errors/, 'wdlint reports processing instruction syntax failure');
is($bad_pi_err, '', 'wdlint writes no stderr for invalid processing instruction file');

my ($bad_subst_out, $bad_subst_err, $bad_subst_rc)=run_cmd($^X, '-Ilib', $script, $bad_subst_fn);
ok($bad_subst_rc != 0, 'wdlint exits non-zero on invalid substitution');
like($bad_subst_out, qr/\Q$bad_subst_fn\E/, 'wdlint reports substitution source filename on error');
like($bad_subst_out, qr/syntax error|had compilation errors/, 'wdlint reports substitution syntax failure');
is($bad_subst_err, '', 'wdlint writes no stderr for invalid substitution file');

my ($bad_multi_out, $bad_multi_err, $bad_multi_rc)=run_cmd($^X, '-Ilib', $script, $bad_multi_fn);
ok($bad_multi_rc != 0, 'wdlint exits non-zero on multiple invalid chunks');
like($bad_multi_out, qr/\Q$bad_multi_fn\E line 2/, 'wdlint reports first invalid chunk line');
like($bad_multi_out, qr/\Q$bad_multi_fn\E line 3/, 'wdlint reports second invalid chunk line');
is($bad_multi_err, '', 'wdlint writes no stderr for multiple invalid chunks file');

my ($good_lookup_out, $good_lookup_err, $good_lookup_rc)=run_cmd($^X, '-Ilib', $script, $good_lookup_fn);
is($good_lookup_rc, 0, 'wdlint ignores non-Perl substitution operators');
like($good_lookup_out, qr/\Q$good_lookup_fn\E syntax OK/, 'wdlint reports syntax OK for non-Perl substitution file');
is($good_lookup_err, '', 'wdlint writes no stderr for non-Perl substitution file');

done_testing();

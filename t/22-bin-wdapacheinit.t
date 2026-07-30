use strict;
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_module);
use File::Temp qw(tempdir);
use File::Spec;

my $script=File::Spec->catfile('bin', 'wdapacheinit');
ok(-f $script, 'wdapacheinit script exists');

my ($version_out, $version_err, $version_rc)=run_cmd($^X, '-Ilib', $script, '--version');
is($version_rc, 0, 'wdapacheinit --version exits cleanly');
like($version_out, qr/wdapacheinit version: \S+/, 'wdapacheinit --version reports script version');
is($version_err, '', 'wdapacheinit --version writes no stderr');

my $stub_dn=tempdir(CLEANUP => 1);
write_module($stub_dn, 'WebDyne::Install::Apache', <<'END_MODULE');
package WebDyne::Install::Apache;
use strict;
use warnings;
sub install {
    my ($class, $prefix_dn, $realbin, $opt_hr)=@_;
    print "method=install\n";
    print "cache=$opt_hr->{webdyne_cache_dn}\n" if exists $opt_hr->{webdyne_cache_dn};
    print "text=$opt_hr->{text}\n" if exists $opt_hr->{text};
    return \0;
}
sub uninstall {
    my ($class, $prefix_dn, $realbin, $opt_hr)=@_;
    print "method=uninstall\n";
    print "cache=$opt_hr->{webdyne_cache_dn}\n" if exists $opt_hr->{webdyne_cache_dn};
    print "text=$opt_hr->{text}\n" if exists $opt_hr->{text};
    print "mp2=$opt_hr->{mp2}\n" if exists $opt_hr->{mp2};
    return \0;
}
1;
END_MODULE

my ($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--uninstall', '--cache', '/tmp/webdyne-cache', '--text', '--mp2'
);
is($rc, 0, 'wdapacheinit stubbed uninstall exits cleanly');
like($stdout, qr/method=uninstall/, 'wdapacheinit dispatches uninstall mode');
like($stdout, qr/cache=\/tmp\/webdyne-cache/, 'wdapacheinit forwards cache option');
like($stdout, qr/text=1/, 'wdapacheinit forwards text option');
like($stdout, qr/mp2=1/, 'wdapacheinit forwards mp2 option');
is($stderr, '', 'wdapacheinit stubbed uninstall writes no stderr');

($stdout, $stderr, $rc)=run_cmd(
    $^X, '-I', $stub_dn, '-Ilib', $script,
    '--dump_opt',
    '--webdyne-cache-dn', '/tmp/webdyne-cache',
    '--dir-apache-conf', '/tmp/apache-conf',
    '--file-mod-perl-lib', '/tmp/mod_perl.so',
);
isnt($rc, 0, 'wdapacheinit --dump_opt aborts after dumping options');
is($stdout, '', 'wdapacheinit --dump_opt writes no stdout');
like($stderr, qr/'dump_opt'\s*=>\s*1/, 'wdapacheinit --dump_opt dumps dump_opt flag');
like($stderr, qr/'webdyne_cache_dn'\s*=>\s*'\/tmp\/webdyne-cache'/, 'wdapacheinit accepts hyphenated cache alias');
like($stderr, qr/'dir_apache_conf'\s*=>\s*'\/tmp\/apache-conf'/, 'wdapacheinit accepts hyphenated Apache config alias');
like($stderr, qr/'file_mod_perl_lib'\s*=>\s*'\/tmp\/mod_perl\.so'/, 'wdapacheinit accepts hyphenated mod_perl alias');

done_testing();

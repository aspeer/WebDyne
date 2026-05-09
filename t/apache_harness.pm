package apache_harness;

use strict;
use warnings;

use Cwd qw(fastcwd);
use File::Spec;
use File::Temp qw(tempdir);


sub startup {


    #  Optional startup options are reserved for future use.
    #
    my $opt_hr=shift();


    #  Server root tmpdir
    #
    my $svr_root_dn=tempdir(
        'webdyne_apache_XXXXXXXX',
        TMPDIR  => 1,
        CLEANUP => 1,
    );


    #  Start Apache server. Mask warnings about duplicate options.
    #
    local $SIG{__WARN__}=sub {
        return if $_[0] =~ /Duplicate specification/;
        CORE::warn @_;
    };


    #  Runner object init
    #
    require Apache::TestRunPerl;
    my $runner=Apache::TestRunPerl->new()
        || die "unable to create Apache::TestRunPerl instance";


    #  Get postamble with WebDyne config
    #
    my $postamble=&startup_conf();


    #  Choose a random port the Apache::Test way and generate config.
    #
    my @argv=(
        '-port'         => 'select',
        '-serverroot'   => $svr_root_dn,
        '-documentroot' => File::Spec->catdir(fastcwd(), 't'),
        '-postamble'    => $postamble,
        '-one-process',
        '-start-httpd',
    );


    #  Start the server.
    #
    $runner->run(@argv);


    #  Done, return runner object
    #
    return $runner;

}


sub startup_conf {


    #  Get all WEBDYNE_CONF env vars
    #
    my @PerlSetEnv=map { sprintf('PerlSetEnv %s %s', $_, $ENV{$_}) } grep { /^WEBDYNE_/ } keys %ENV;
    push(@PerlSetEnv, 'PerlSetEnv WEBDYNE_ERROR_TEXT 1') unless defined($ENV{'WEBDYNE_ERROR_TEXT'});
    my $PerlSetEnv=join("\n", @PerlSetEnv);
    return <<"END";
$PerlSetEnv
PerlSetEnv WEBDYNE_CONF .
PerlSwitches -I../lib
PerlModule WebDyne
AddHandler modperl .psp
PerlResponseHandler WebDyne
END

}


sub shutdown {

    my $runner=shift();
    return unless $runner && $runner->{'server'};
    $runner->{'server'}->stop();
    return;

}


1;

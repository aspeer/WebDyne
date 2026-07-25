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


    #  Don't need ulimit
    #
    $ENV{'APACHE_TEST_ULIMIT_SET'}++;


    #  Don't need index.html generated
    #
    no warnings qw(once redefine);
    *Apache::TestConfig::generate_index_html=sub {};


    #  Don't want include libraries changes, stuf this out
    #
    *Apache::TestConfig::configure_startup_pl=sub {};


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
    my @perl_inc_dn=@{&perl_inc_dn()};
    my $PerlSwitches=join("\n", map { sprintf('PerlSwitches -I%s', $_) } @perl_inc_dn);
    my @PerlSetEnv=map { sprintf('PerlSetEnv %s %s', $_, $ENV{$_}) } grep { /^WEBDYNE_/ } keys %ENV;
    push(@PerlSetEnv, 'PerlSetEnv WEBDYNE_ERROR_TEXT 1') unless defined($ENV{'WEBDYNE_ERROR_TEXT'});
    my $PerlSetEnv=join("\n", @PerlSetEnv);
    return <<"END";
$PerlSetEnv
$PerlSwitches
PerlSetEnv WEBDYNE_CONF .
#PerlSwitches -I../lib
PerlModule WebDyne
AddHandler modperl .psp
PerlResponseHandler WebDyne
END

}


sub perl_inc_dn {

    my %default_inc=map { $_ => 1 } @{ perl_inc_dn_default() || [] };
    my %seen;
    my @lib=grep {
        !$default_inc{$_} && !$seen{$_}++
    } map {
        File::Spec->rel2abs($_)
    } grep {
        defined($_) && !ref($_) && length($_) && -d $_
    } @INC;

    return \@lib;
}


sub perl_inc_dn_default {

    my @default_inc;
    #local %ENV=%ENV;
    #delete @ENV{qw(PERL5LIB PERLLIB PERL_USE_UNSAFE_INC)};

    if (open(my $perl_fh, '-|', $^X, '-e', 'print join qq(\0), grep { defined && !ref && length && -d } @INC')) {
        local $/;
        my $inc=<$perl_fh>;
        close($perl_fh);
        @default_inc=map {
            File::Spec->rel2abs($_)
        } split(/\0/, ($inc || ''));
    }

    return \@default_inc;
}


sub shutdown {

    my $runner=shift();
    return unless $runner && $runner->{'server'};
    $runner->{'server'}->stop();
    return;

}


1;

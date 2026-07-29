package apache_harness;

use strict;
use warnings;

use Cwd qw(fastcwd);
use File::Spec;
use WebDyne::Util qw(apache_startup apache_shutdown perl_inc_dn);


sub startup {


    #  Optional startup options are reserved for future use.
    #
    my $opt_hr=shift();


    #  Get postamble with WebDyne config
    #
    my $postamble=&startup_conf();


    #  Start Apache using Apache::Test.
    #
    return apache_startup({
        port         => 'select',
        documentroot => File::Spec->catdir(fastcwd(), 't'),
        postamble    => $postamble,
        die_on_error => 1,
    });

}


sub startup_conf {


    #  Get all WEBDYNE_CONF env vars
    #
    my @perl_inc_dn=@{&perl_inc_dn()};
    my $PerlSwitches=join("\n", map { sprintf('PerlSwitches -I%s', $_) } @perl_inc_dn);
    my @PerlSetEnv=map { sprintf('PerlSetEnv %s %s', $_, $ENV{$_}) } grep { $ENV{$_} } grep { /^WEBDYNE_/ } keys %ENV;
    push(@PerlSetEnv, 'PerlSetEnv WEBDYNE_ERROR_TEXT 1') unless defined($ENV{'WEBDYNE_ERROR_TEXT'});
    my $PerlSetEnv=join("\n", @PerlSetEnv);
    my $postamble= <<"END";
$PerlSetEnv
$PerlSwitches
PerlSetEnv WEBDYNE_CONF .
PerlSetEnv WEBDYNE_HEAD_INSERT 0
#PerlSwitches -I../lib
PerlModule WebDyne
AddHandler modperl .psp
PerlResponseHandler WebDyne
END
;
    return $postamble;
}


sub shutdown {

    return apache_shutdown(@_);

}


1;

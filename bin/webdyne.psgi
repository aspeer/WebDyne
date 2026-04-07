#!/usr/bin/env perl
#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2026 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#


#  Pragma
#
use strict;
use vars   qw($VERSION);
use warnings;


#  External modules
#
use Cwd qw(fastcwd);
use Data::Dumper;
use File::Basename;
use File::Spec;


#  PSGI modules we need
#
use Plack::Builder;
use WebDyne::PSGI;
use WebDyne::Constant;
use WebDyne::PSGI::Constant;


#  Version Info, must be all one line for MakeMaker, CPAN.
#
$VERSION='2.078_599';


#  Called from command line ?
#
if (!caller || exists $ENV{PAR_TEMP}) {


    #  Yes. Get options
    #
    my %opt=(
        test    => 0,
        static  => 1,
        index   => 1,
        %{do(glob(sprintf('~/.%s.opt', basename(__FILE__)))) || {}}
    );


    #  Process
    #
    require Getopt::Long;
    Getopt::Long::Configure('pass_through');
    Getopt::Long::GetOptions(
        \%opt,
        'test!',
        'static!',
        'index!',
        'root:s',
        'argv:s'
    );
    
    
    #  Last argument is root directory
    #
    if (@ARGV && $ARGV[-1] !~ /^--?/) {
        $opt{'root'} = pop @ARGV;
    }
    else {
        $opt{'root'} ||=($ENV{'DOCUMENT_ROOT'} ||  fastcwd());
    }
    
    
    #  Startup
    #
    exit &startup(\%opt, split(/\s+/, $opt{'argv'}), @ARGV);

}
else {

    # No - called from pagi_server. Need document root and doc default from 
    # env or var
    #
    my %opt=(
        root    => $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT || fastcwd(),
        index   => $ENV{'DOCUMENT_DEFAULT'} || $DOCUMENT_DEFAULT
    );
    return &build(\%opt);
    
}



#==================================================================================================


sub build {


    #  Build app code ref, options passed for builder
    #
    my $opt_hr=shift();
    my $builder_or=Plack::Builder->new();
    
    
    #  Adjust static service config var based on opts if
    #  they exist
    #
    if (exists($opt_hr->{'static'})) {
        $WEBDYNE_PSGI_STATIC=$opt_hr->{'static'};
    }
    
    
    #  Add in any middleware in config file
    #
    foreach my $middleware_ar (@{$WEBDYNE_PSGI_MIDDLEWARE}) {
        my ($middleware, $middleware_opt_hr)=@{$middleware_ar};
        
        #  Skip static if not wanted
        #
        if ($middleware eq 'Static') {
            next unless $WEBDYNE_PSGI_STATIC;
        }
        
        
        #  And code refs are run and given opt as first param
        #
        if (ref($middleware_opt_hr) eq 'CODE') {
            $middleware_opt_hr=$middleware_opt_hr->($opt_hr);
        }
        
        
        #  Now add it
        #
        $builder_or->add_middleware($middleware, %{$middleware_opt_hr});
    }
    

    #  Read in local webdyne.conf.pl
    #
    #&local_constant_load($opt_hr->{'root'});


    #  Finally return as app code ref
    #
    return $builder_or->to_app(
        WebDyne::PSGI->new(%{$opt_hr})->to_app())

}


sub startup {


    #  Get WebDyne::PSGI options and Plack::Runner args
    #
    my ($opt_hr, @argv)=@_;
    
    
    #  Running from command line without being stared by plackup or starman
    #
    require Plack::Runner;
    my $plack_or=Plack::Runner->new();
    

    #  Mac conflicts with Plack default port of 5000 - choose 5001
    #
    if ($^O eq 'darwin') {
        $plack_or->parse_options('--port', '5001', @argv) unless grep { /--port/ } @argv
    }
    else {
        $plack_or->parse_options(@argv);
    }
    

    #  Read in local webdyne.conf.pl
    #
    &local_constant_load($opt_hr->{'root'});


    #  Get app code ref from WebDyne::PAGI
    #
    my $app_cr=&build($opt_hr);

    
    #  Run it
    #
    #*PAGI::Runner::load_app=sub { return $app_cr };
    exit $plack_or->run($app_cr);

}


sub local_constant_load {


    #  Read in local webdyne.conf.pl
    #
    my $root_dn=shift();
    
    
    #  If root_dn is a file get dir name
    #
    if (-f $root_dn) {
        $root_dn=(File::Spec->splitpath($root_dn))[1];
    }
    WebDyne::Constant->import(File::Spec->catfile($root_dn, sprintf('.%s', $WEBDYNE_CONF_FN)));

}

__END__

sub normalize_dn {

    #  Normal dir, normally document_root
    #
    my $rel_dn=shift();
    my $abs_dn=File::Spec->rel2abs($rel_dn);
    $abs_dn =~ s{/$}{} unless $abs_dn eq '/';
    return $abs_dn;
    
}



#!/bin/perl
# 
#  Compare generated files with frozen reference files
#
use strict qw(vars);
use warnings;
use vars   qw($VERSION);


#  Load
#
use Test::More qw(no_plan);
use FindBin qw($RealBin $Script);
use File::Temp qw(tempfile);
use File::Find qw(find);
use Data::Dumper;
use IO::File;
use IO::String;
use Cwd qw(abs_path);
$Data::Dumper::Indent=1;
use Storable qw(lock_retrieve freeze);
$Storable::canonical=1;


#  Load WebDyne
#
require_ok('WebDyne::Compile');
require_ok('WebDyne::Request::Fake');
use WebDyne::Util;


#  Setup environment for this test if not already present
#
$ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '02';
#die Dumper(\%INC, \@INC);


#  Run
#
exit(${&main(\@ARGV) || die err ()} || 0);    # || 0 stops warnings

#==================================================================================================


sub err_carp {

    require Carp;
    $Carp::CarpLevel=0;
    $Carp::RefArgFormatter = sub {
        require Data::Dumper;                                                                                                                                                
        $Data::Dumper::Indent=1;
        Data::Dumper->Dump(\@_); # not necessarily safe                                                                                                                    
    };
    &Carp::confess &diag(@_);
    
}



sub main {

    #  Get list of files either from command line or from *.psp if no
    #  command line given
    #
    my @test_fn=@{shift()};
    if (my $test_fn=$ENV{'WEBDYNE_TEST_FILE'}) {
        @test_fn=map { glob $_ } split(/[;,]/, $test_fn);
    }
    my $wanted_cr=sub { push (@test_fn, $File::Find::name) if /\.psp$/ };
    find($wanted_cr, $RealBin) unless @test_fn;


    #  Create a new compile instance
    #
    my $compile_or=WebDyne::Compile->new() ||
        return err();
        
        
    #  Data dir
    #
    my $data_freeze_dn='data';


    #  Iterate over files
    #
    diag('');
    FILE: foreach my $test_fn (sort {$a cmp $b } @test_fn) {


        #  Create WebDyne render of PSP file and capture to file
        #
        debug("processing $test_fn");
        my $test_cn=abs_path($test_fn) ||
            return err("unable to determine full path of $test_fn");
        (-f $test_cn) ||
            return err("unable to find file: $test_fn");
        diag("processing: $test_fn");
        
        for (0..1) {
        foreach my $stage ((0..5), 'final') {


            #  Get data file
            #
            my ($data_dn, $data_fn)=(File::Spec->splitpath($test_cn))[1,2];


            #  Enables variations on a single source file
            #
            $data_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $data_fn);
            my $data_cn=File::Spec->catfile($data_dn, $data_freeze_dn, $data_fn);
            $data_cn=~s/\.psp$/\.dat\.${stage}/;


            #  Compile to desired stage
            #
            my $stage_name=($stage eq 'final') ? $stage : "stage${stage}";


            #  Options. Use test_fn rather than test_fp so manifest only has file name
            #
            my %opt=(

                srce        	=> $test_cn,
                nofilter	=> 1,
                noperl		=> 1,
                notimestamp	=> 1,
                nomanifest	=> 1,
                $stage_name     => 1
                
            );
            
            
            #  Get it
            #
            my $data_live_ar=$compile_or->compile(\%opt) ||
                return err ();
            debug("data_live_ar %s", Dumper($data_live_ar));
            
            
            #  Get previous version
            #
            (-f $data_cn) || do {
                diag("skipping $test_fn, no data file - run maketest.pl");
                return err();
                #next FILE;
            };
            my $data_thaw_ar=lock_retrieve($data_cn) ||
                return err();



            #  Now compare
            #
            my $string_live=freeze($data_live_ar);
            my $string_thaw=freeze($data_thaw_ar);
            
            if ($string_live eq $string_thaw) {
                pass("$test_fn pass on stage: $stage");
            }
            else {
                fail(diag("$test_fn fail on stage: $stage"));
                eval { require Text::Diff } || do {
                    diag('unable to load Text::Diff module to show comparison');
                    next;
                };
                my $diff=Text::Diff::diff(
                    \Dumper($data_live_ar),
                    \Dumper($data_thaw_ar),
                    { STYLE => 'Unified' }
                );
                diag("diff: $diff");
                #diag(sprintf('%s:%s', Dumper($data_live_ar, $data_thaw_ar)));
            }

        } #foreach stage
        
        
        #  Now HTML
        #
        #diag("processing: $test_fn stage: HTML render");
        my ($data_dn, $data_fn)=(File::Spec->splitpath($test_cn))[1,2];
        $data_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $data_fn);

        my $data_cn=File::Spec->catfile($data_dn, $data_freeze_dn, $data_fn);
        $data_cn=~s/\.psp$/\.html/;


        my $html_live_sr=&render($test_cn) ||
            return err();
        #diag("render: *${$html_live_sr}*");

        (-f $data_cn) || do {
            diag("skipping $test_fn, no data file - run maketest.pl");
            next;
        };
        my $html_thaw_fh=IO::File->new($data_cn, O_RDONLY) ||
            return err("unable to open $data_cn, $!");
        local $/;
        my $html_thaw=<$html_thaw_fh>;
        $html_thaw_fh->close();

        if (${$html_live_sr} eq $html_thaw) {
            pass("$test_fn pass on stage: HTML render");
        }
        else {
            fail(diag("$test_fn fail on stage: HTML render"));
            eval { require Text::Diff } || do {
                diag('unable to load Text::Diff module to show comparison');
                next;
            };
            my $diff=Text::Diff::diff(
                \Dumper(${$html_live_sr}),
                \Dumper($html_thaw),
                { STYLE => 'Unified' }
            );
            diag("diff: $diff");
            diag(sprintf('%s:%s', Dumper($html_live_sr, \$html_thaw)));
        }
        }

        #ok(${$html_sr} eq $html, "$test_fn pass on stage: render");
        ##die ${$html_sr};


    }
    


    #  Done
    #
    return \undef
    
}


sub render {


    #  Where is our source and dest
    #
    my $srce_fn=shift();


    #  Get scalar we can select to
    #
    my $html;
    my $html_fh=IO::String->new($html);


    #  Render to dest file
    #
    my $r=WebDyne::Request::Fake->new( 
        filename	=> $srce_fn, 
        select		=> $html_fh,
        noheader	=> 1 
    );
    defined(WebDyne->handler($r)) ||
        return err('render error');
    $r->DESTROY();
    $html_fh->close();


    #  Manual cleanup
    #
    #diag('render: ok');


    #  Done, return success
    #
    return \$html;

}



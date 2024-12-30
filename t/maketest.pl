#!/bin/perl
#
#  Create data files in test directory from PSP sources
#
use strict qw(vars);
use warnings;
use vars   qw($VERSION);


#  External Modules
#
use WebDyne::Request::Fake;
use WebDyne::Compile;
use WebDyne;
use File::Find qw(find);
use File::Spec;
use IO::File;
use HTML::TreeBuilder;
use Storable qw(lock_store);
use FindBin qw($RealBin $Script);
use Cwd qw(abs_path);
use Carp qw(confess);
$Storable::canonical=1;


#  WebDyne Modules
#
use WebDyne::Request::Fake;
use WebDyne::Compile;
use WebDyne;


#  Run
#
exit(${&main(\@ARGV) || die err ()} || 0);    # || 0 stops warnings

#==================================================================================================

sub main {


    #  Get list of files either from command line or from *.psp if no
    #  command line given
    #
    my @test_fn=@{shift()};
    my $wanted_cr=sub { push (@test_fn, $File::Find::name) if /\.psp$/ };
    find($wanted_cr, $RealBin) unless @ARGV;


    #  Create a new compile instance
    #
    my $compile_or=WebDyne::Compile->new() ||
        return err();


    #  Iterate over files
    #
    foreach my $test_fn (sort {$a cmp $b } @test_fn) {


        #  Create WebDyne render of PSP file and capture to file
        #
        my $test_fp=abs_path($test_fn) ||
            return err("unable to determine full path of $test_fn");
        (-f $test_fp) ||
            return err("unable to find file: $test_fn");
        $test_fn=(File::Spec->splitpath($test_fp))[2];
        diag("processing: $test_fn");
        
        
        #  Start stepping through compile stages
        #
        foreach my $stage ((0..5), 'final') {


            #  Create dest file name
            #
            diag("processing: $test_fn stage: $stage");
            (my $dest_fp=$test_fp)=~s/\.psp$/\.dat\.${stage}/;
            my $dest_fn=(File::Spec->splitpath($dest_fp))[2];
            

            #  Compile to desired stage
            #
            my $stage_name=($stage eq 'final') ? $stage : "stage${stage}";


            #  Options. Use test_fn rather than test_fp so manifest only has file name
            #
            my %opt=(

                srce        	=> $test_fn,
                nofilter	=> 1,
                noperl		=> 1,
                notimestamp	=> 1,
                $stage_name	=> 1
                
            );
            
            
            #  Compile
            #
            my $data_ar=$compile_or->compile(\%opt) ||
                return err ();
            
            
            #  Save result
            #
            #diag("wrote: $dest_fn");
            lock_store($data_ar, $dest_fp);

        }
        
        
        #  Now HTML
        #
        diag("processing: $test_fn stage: render");
        (my $dest_fp=$test_fp)=~s/\.psp$/\.html/;
        &render($test_fn, $dest_fp) ||
            return err();
        
        
        #  And tree
        #
        diag("processing: $test_fn stage: treebuild");
        ($dest_fp=$test_fp)=~s/\.psp$/\.tree/;
        &treebuild($test_fn, $dest_fp) ||
            return err();

        
    }
    
    #   Done
    #
    return \undef;
    
}


sub treebuild {


    #  Convert HTML file to tree dump
    #
    my ($srce_fn, $dest_fn)=@_;


    #  Create TreeBuilder dump of rendered text in temp file
    #
    my $dest_fh=IO::File->new($dest_fn, O_WRONLY|O_CREAT|O_TRUNC) ||
      return err("unable to create dump file $dest_fn, $!");
    my $html_fh=IO::File->new($srce_fn, O_RDONLY);
    my $tree_or=HTML::TreeBuilder->new();
    while (my $html=<$html_fh>) {
	#  Do this way to get rid of extraneous CR's older version of CGI insert, spaces
	#  after tags which also differ from ver to ver, confusing test
	$html=~s/\n+$//;
	$html=~s/>\s+/>/g;
	$tree_or->parse($html);
    }
    $tree_or->eof();
    $html_fh->close();
    $tree_or->dump($dest_fh);
    $tree_or->delete();
    $dest_fh->close();
    diag('treebuild: ok');
    return \undef;


}


sub render {


    #  Where is our source and dest
    #
    my ($srce_fn, $dest_fn)=@_;


    #  Open dest file handle
    #
    my $dest_fh=IO::File->new($dest_fn, O_CREAT | O_TRUNC | O_WRONLY) ||
        return err ("unable to open file $dest_fn for output, $!");


    #  Render to dest file
    #
    my $r=WebDyne::Request::Fake->new( 
        filename	=> $srce_fn, 
        select		=> $dest_fh, 
        noheader	=> 1 
    );
    defined(WebDyne->handler($r)) ||
        return err('render error');
    $r->DESTROY();
    $dest_fh->close();


    #  Manual cleanup
    #
    $r->DESTROY();
    diag('render: ok');


    #  Done, return success
    #
    return \undef;

}


sub diag {

    print ((my $diag=sprintf(shift() || 'unknown error', @_)), $/);
    return $diag;
    
}


sub err {

    $Carp::CarpLevel=1;
    $Carp::RefArgFormatter = sub {
        require Data::Dumper;                                                                                                                                                
        $Data::Dumper::Indent=1;
        Data::Dumper->Dump(\@_); # not necessarily safe                                                                                                                    
    };
    confess &diag(@_);
    
}


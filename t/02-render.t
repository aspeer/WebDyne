#!perl


#  Load
#
use Test::More qw(no_plan);
BEGIN { use_ok( 'HTML::TreeBuilder' ); }
use WebDyne::Request::Fake;
use FindBin qw($RealBin $Script);
use File::Temp qw(tempfile);
use Digest::MD5;
use File::Find qw(find);
use IO::File;


#  Load WebDyne
#
require_ok('WebDyne');


#  Get test files
#
my @test_fn;
my $wanted_sr=sub { push (@test_fn, $File::Find::name) if /\.psp$/ };
find($wanted_sr, $RealBin);
foreach my $test_fn (sort {$a cmp $b } @test_fn) {
    #diag("testing file $test_fn");
    my $r=WebDyne::Request::Fake->new( filename=>$test_fn );
    ok($r, 'request created');



    #  Capture output
    #
    my ($temp_fh, $temp_fn)=tempfile();
    #diag("temp_fh $temp_fh, temp_fn $temp_fn");
    my $select_fh=select;
    select $temp_fh;
    ok(defined(WebDyne->handler($r)), 'webdyne handler');
    $r->DESTROY();
    $temp_fh->close();
    select $select_fh;


    #  Create TreeBuilder dump of rendered text
    #
    my ($tree_fh, $tree_fn)=tempfile();
    my $tree_or=HTML::TreeBuilder->new_from_file($temp_fn);
    ok($tree_or, 'HTML::TreeBuilder object');
    $tree_or->dump($tree_fh);
    $tree_or->delete();
    #diag("tree_fn $tree_fn");
    seek($tree_fh,0,0);


    #  Get MD5 of file we just rendered
    #
    my $md5_or=Digest::MD5->new();
    $md5_or->addfile($tree_fh);
    my $md5_tree=$md5_or->hexdigest();


    #  Now of reference dump in test directory
    #
    (my $dump_fn=$test_fn)=~s/\.psp$/\.dmp/;
    my $dump_fh=IO::File->new($dump_fn, O_RDONLY);
    ok($dump_fh, "loaded render dump file for $dump_fn");
    $dump_fh->binmode();
    $md5_or->reset();
    $md5_or->addfile($dump_fh);
    my $md5_dump=$md5_or->hexdigest();
    #diag("tree $md5_tree, dump $md5_dump");
    ok($md5_tree eq $md5_dump, "render $test_fn");


    #  Clean up
    #
    $tree_fh->close();
    $dump_fh->close();
    unlink($temp_fn, $tree_fn);
}


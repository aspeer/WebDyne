#  Pragma
#
use strict;
use warnings;


#  Test Harness
#
use Test::More;


#  Skip test if missing any modules or no mod_perl
#
BEGIN {
    my @missing;
    for my $m (qw(Plack::Test)) {
        eval "require $m; 1" or push @missing, $m;
    }
    if (@missing) {
        plan skip_all => "Skipping PSGI tests: missing " . join(", ", @missing);
    }
    plan skip_all => "AUTHOR_TEST not set, omitting PSGI test" unless $ENV{'AUTHOR_TEST'};
    
}


#  Skip any local config
#
BEGIN { 
    $ENV{'WEBDYNE_CONF'}='.'; 
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
}


#  Modules we need
#
use FindBin qw($RealBin $Script);
use File::Find qw(find);
use File::Basename;
use Data::Dumper;
use IO::File;
use Cwd qw(abs_path);
use Plack::Test;
use HTTP::Request::Common qw(GET);


#  Load WebDyne modules we need
#
use WebDyne::PSGI;
use WebDyne::Util;


#  Module config
#
$Data::Dumper::Indent=1;
$Data::Dumper::Sortkeys=1;


#  Setup environment for this test.
#
$ENV{'WEBDYNE_TEST_FILE_PREFIX'} ||= '02';


#  Startup the web server and run tests
#
#my $runner=&startup();
ok(${&main(\@ARGV) || die err ()} || 0);    # || 0 stops warnings
#print STDERR GET_BODY('version.psp');
done_testing();


#  Main comparison routine
#
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
    #diag(sprintf('files: %s'), Dumper(\@test_fn));


    #  Data dir
    #
    my $data_freeze_dn='data';
    
    
    #  Get app code
    #
    use Cwd qw(fastcwd);
    diag(fastcwd());
    ok(my $app_cr=WebDyne::PSGI->new(root=>File::Spec->catdir(fastcwd(), 't'))->to_app());
    ok(my $test_or=Plack::Test->create($app_cr));


    #  Iterate over files
    #
    diag('');
    
    
    #  Repeat as required
    #
    for (1 .. ($ENV{'WEBDYNE_TEST_REPEAT'} || 1)) {
        FILE: foreach my $test_fn (sort {$a cmp $b } @test_fn) {


            #  Create WebDyne render of PSP file and capture to file
            #
            debug("processing $test_fn");
            my $test_cn=abs_path($test_fn) ||
                return err("unable to determine full path of $test_fn");
            (-f $test_cn) ||
                return err("unable to find file: $test_fn");
            diag("processing: $test_fn");
            
            #next if $test_cn=~/substitution\.psp$/;
            #next if $test_cn=~/api_bare\.psp$/;

            #  Iterate twice to make sure no change over multiple iterations
            #
            foreach my $count (1..2) {
            
            
                
                #  Now HTML
                #
                my ($data_dn, $data_fn)=(File::Spec->splitpath($test_cn))[1,2];
                $data_fn=join('-', grep {$_} $ENV{'WEBDYNE_TEST_FILE_PREFIX'},  $data_fn);
                my $data_cn=File::Spec->catfile($data_dn, $data_freeze_dn, $data_fn);
                $data_cn=~s/\.psp$/\.html/;
                #diag($test_cn);

                
                #  Get from Apache
                #
                #my $html_live=GET_BODY(basename($test_cn));
                ok(my $res=$test_or->request(GET (basename($test_cn) || $test_cn)));
                my $html_live=$res->decoded_content();
                #diag("live: $html_live");
                

                #  Check match
                #
                (-f $data_cn) || do {
                    diag("skipping $test_fn, no data file - run maketest.pl");
                    next;
                };
                my $html_thaw_fh=IO::File->new($data_cn, O_RDONLY) ||
                    return err("unable to open $data_cn, $!");
                local $/;
                my $html_thaw=<$html_thaw_fh>;
                $html_thaw_fh->close();
                #diag("thaw: $html_thaw");
                
                #  Yes ?
                #
                if ($html_live eq $html_thaw) {
                
                    #  OK
                    #
                    pass("$test_fn pass on stage: HTML render");
                    #diag("$test_fn .. [OK]");
                }
                else {
                
                    #  Fail
                    #
                    fail(diag("$test_fn fail on stage: HTML render"));
                    eval { require Text::Diff } || do {
                        diag('unable to load Text::Diff module to show comparison');
                        next;
                    };
                    my $diff=Text::Diff::diff(
                        \Data::Dumper->Dump([\$html_live], ['$ACTUAL']),
                        \Data::Dumper->Dump([\$html_thaw], ['$EXPECT']),
                        { STYLE => 'Unified' }
                    );
                    diag("diff: $diff");
                    #diag(sprintf('%s:%s', Dumper($html_live_sr, \$html_thaw)));
                }

            }

        }
    }


    #  Done
    #
    return \1;
    
}



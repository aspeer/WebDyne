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
    for my $m (qw(Apache::Test Apache::TestRunPerl Apache::TestRequest mod_perl2)) {
        eval "require $m; 1" or push @missing, $m;
    }
    if (@missing) {
        plan skip_all => "Skipping mod_perl tests: missing " . join(", ", @missing);
    }
    plan skip_all => "AUTHOR_TEST not set, omitting mod_perl test" unless $ENV{'AUTHOR_TEST'};
}


#  Modules we need
#
use FindBin qw($RealBin $Script);
use File::Find qw(find);
use File::Basename;
use Data::Dumper;
use IO::File;
use Cwd qw(abs_path);
use Apache::TestRequest qw(GET_BODY);
use File::Temp qw(tempdir);


#  Load WebDyne module for debug
#
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
my $runner=&startup();
ok(${&main(\@ARGV) || die err ()} || 0);    # || 0 stops warnings
#print STDERR GET_BODY('version.psp');
done_testing();
$runner->{'server'}->stop();


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
                my $html_live=GET_BODY(basename($test_cn));
                
                
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
    return \1
    
}


sub startup {


    #  Startup Apache test instance
    #
    my $opt_hr=shift();
    

    #  Server root tmpdir
    #
    my $svr_root_dn=tempdir(
        'webdyne_apache_XXXXXXXX',
        TMPDIR  => 1,
        CLEANUP => 1,   # we’ll stop httpd first, then remove manually
    );


    #  Start Apache server. Mask warnings about duplicate options
    #
    local $SIG{__WARN__}=sub { 
        return if $_[0] =~ /Duplicate specification/;
        CORE::warn @_;
    };


    #  Runner object init
    #
    require Apache::TestRunPerl;
    my $runner = Apache::TestRunPerl->new() ||
        return err('unable to create Apache::TestRunPerl instance');
        
        
    #  Get postamble with WebDyne config
    #
    my $postamble=&startup_conf();


    # Choose a random port the "Apache::Test" way: -port=select
    # And tell it we intend to start httpd (so it generates config)
    #
    use Cwd qw(fastcwd);
    my @argv=(
        '-port'         => 'select', 
        '-serverroot'   => $svr_root_dn,
        '-documentroot' => File::Spec->catdir(fastcwd(), 't'),
        '-postamble'    => $postamble,
        '-one-process',
        '-start-httpd'
    );


    #  Now start. Will die if can't start
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
    push (@PerlSetEnv, "PerlSetEnv WEBDYNE_ERROR_TEXT 1") unless defined($ENV{'WEBDYNE_ERROR_TEXT'});
    my $PerlSetEnv=join("\n", @PerlSetEnv);
    return <<"END"
$PerlSetEnv
PerlSetEnv WEBDYNE_CONF .
PerlSwitches -I../lib
PerlModule WebDyne
AddHandler modperl .psp
PerlResponseHandler WebDyne
END

}


sub startup0 {


    #  Start Apache server. Mask warnings about duplicate options
    #
    local $SIG{__WARN__}=sub { 
        return if $_[0] =~ /Duplicate specification/;
        CORE::warn @_;
    };


    #  Runner config.
    my $runner = Apache::TestRunPerl->new();
    diag('');


    # Choose a random port the "Apache::Test" way: -port=select
    # And tell it we intend to start httpd (so it generates config)
    #
    my @argv = ('-port=select', '-start-httpd');

    # Minimal subset of what Apache::TestRun->run(@argv) does before start()
    #
    $runner->getopts(\@argv);              # parse options into $runner->{opts}
    $runner->pre_configure();              # setup defaults, env
    $runner->{test_config} = $runner->new_test_config();
    $runner->{test_config}->{server}->{run} = $runner;
    $runner->{server} = $runner->{test_config}->server;
    $runner->{test_config}->httpd_config(); # locate httpd, probe modules, etc.
    $runner->configure();                  # write t/conf/httpd.conf, pick port
    
    
    #  Now start 
    #
    ok($runner->start(), 'httpd start');                      # start apache
    
    
    #  Done
    #
    return $runner;


}
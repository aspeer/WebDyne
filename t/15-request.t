#  Pragma
#
use strict;
no strict qw(refs);
use warnings;


#  Test Harness
#
use Test::More;
use File::Spec;
use Cwd qw(fastcwd);
use Data::Dumper;
use File::Basename qw(dirname basename);
use HTTP::Request::Common qw(GET);
use HTTP::Headers::Fast;
use IO::String;


#  WebDyne modules
#
use WebDyne::Constant;
use WebDyne::Request::Fake;
use WebDyne;


#======================================================================================================================


#  Fake
#
WebDyne->init();
note('WebDyne::Fake test starting');
ok(&render('t/15-request.psp'));
note('WebDyne::Fake test completed');


#  PSGI
#
if (eval { require WebDyne::PSGI; 1 }) {
    note('WebDyne::PSGI test starting');
    require Plack::Test;
    WebDyne->init();
    ok(my $app_cr=WebDyne::PSGI->new(root=>File::Spec->catdir(fastcwd(), 't'))->to_app());
    ok(my $test_or=Plack::Test->create($app_cr));
    ok(my $res=$test_or->request(GET (basename('15-request.psp'), 'X-Test-Header-Req-Get'=>'OK')));
    note('WebDyne::PSGI test completed');
}


#  PAGI
#
if (eval { require WebDyne::PAGI; 1 }) {
    note('WebDyne::PAGI test starting');
    require PAGI::Test::Client;
    WebDyne->init();
    ok(my $app_cr=WebDyne::PAGI->new(root=>File::Spec->catdir(fastcwd(), 't'))->to_app());
    ok(my $test_or=PAGI::Test::Client->new(app => $app_cr));
    ok(my $res=$test_or->get(basename('15-request.psp'), headers => { 'X-Test-Header-Req-Get'=>'OK' }));
    note('WebDyne::PAGI test completed');
}


#  Apache
#
if (eval { require Apache2::RequestRec; 1 }) {
    note('WebDyne::Apache test starting');
    push @INC, dirname(__FILE__);
    require 't.pm';
    use Apache::TestRequest qw(GET_BODY);
    diag('');
    my $runner=&t::startup;
    my $test_no=Test::Builder->new->current_test();
    my $html_live=GET_BODY(basename('15-request.psp'), 'X-Test-No'=>$test_no, 'X-Test-Header-Req-Get'=>'OK' );
    if ($html_live=~/Test No: (\d+)/) {
        Test::Builder->new->current_test($1);
    }
    note('WebDyne::Apache test completed');
    diag('');
    &t::shutdown($runner);
}


#  Testing finished
#
done_testing();


#======================================================================================================================


sub render {


    #  Where is our source and dest
    #
    my $srce_fn=shift();


    #  Get scalar we can select to
    #
    my $html;
    my $html_fh=IO::String->new($html);
    
    
    #  Headers
    #
    my $headers_in_or=HTTP::Headers::Fast->new(
        'X-Test-Header-Req-Get'=>'OK'
    );


    #  Render to dest file
    #
    my $r=WebDyne::Request::Fake->new( 
        filename	=> $srce_fn, 
        select		=> $html_fh,
        noheader	=> 1,
        headers_in      => $headers_in_or
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


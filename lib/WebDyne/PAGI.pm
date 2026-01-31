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
package WebDyne::PAGI;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  External Modules
#
use HTTP::Status qw(:constants is_success is_error);
use IO::String;
use Data::Dumper;
use Cwd qw(fastcwd);
use Future::AsyncAwait;


#  PAGI modules
#
use PAGI::Request;
use PAGI::Response;
use PAGI::SSE;


#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Util;
use WebDyne::PAGI::Constant;
use WebDyne::Request::PSGI::Constant;
use WebDyne::Request::PAGI;


#  Test file to use if no DOCUMENT_ROOT found
#
(my $test_dn=$INC{'WebDyne.pm'})=~s/\.pm$//;
my $test_fn=File::Spec->catfile($test_dn, 'time.psp');


#  Set DOCUMENT_DEFAULT
#
$DOCUMENT_DEFAULT=$ENV{'DOCUMENT_DEFAULT'} || $DOCUMENT_DEFAULT;


#  Initialise
#
&init();


#  Version information
#
$VERSION='2.075';


#==================================================================================================

sub handler_sse {


    #  Get request
    #
    my ($scope, $receive, $send)=@_;
    debug('in handler, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));


    #  Create helper objects
    #
    my $req_or=PAGI::Request->new($scope, $receive) ||
        return err('unable to get PAGI::Request object');
    my $res_or=PAGI::Response->new($scope, $send) ||
        return err('unable to get PAGI::Response object');
    my $sse_or=PAGI::SSE->new($scope, $receive, $send) ||
        return err('unable to get PAGI::SSE object');
    debug("req_or: $req_or, res_or: $res_or, sse_or: $sse_or");
    
    
    #  Get main WebDyne handler request object
    #
    my $r=WebDyne::Request::PAGI->new( document_root => $DOCUMENT_ROOT, document_default => $DOCUMENT_DEFAULT, scope=>$scope, req=>$req_or, res=>$res_or, sse=>$sse_or,
        receive => $receive, send=> $send) ||
            return err('unable to create new WebDyne::Request::PAGI object: %s', 
                $@ || errclr() || 'unknown error');
    debug("r: $r");
    
    
    #  Call handler. No point error checking but log errors
    #
    debug('calling WebDyne handler');
    my $status=WebDyne->handler($r);
    debug("status: $status");
    if ($status eq HTTP_CONTINUE) {
        my $sse_cr=$r->custom_response($status);
        return $sse_cr;
    }
    else {
        return err();
    }

}


sub handler_sse_error {

    return async sub {
    

        #  Get request
        #
        my ($scope, $receive, $send)=@_;
        debug('in handler, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));


        #  Create helper objects
        #
        my $sse_or=PAGI::SSE->new($scope, $receive, $send) ||
            return err('unable to get PAGI::SSE object');
        debug("sse_or: $sse_or");
        
        
        #  Send error
        #
        await $sse_or->send('SSE error - see logs');
        
    }
    
}


sub handler_http {


    #  Return async sub for handling WebDyne requests
    #
    return async sub {


        #  Get request
        #
        my ($scope, $receive, $send)=@_;
        debug('in handler, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));
        
        
        #  Only need request and response helper objects
        #
        my $req_or=PAGI::Request->new($scope, $receive) ||
            return err('unable to get PAGI::Request object');
        my $res_or=PAGI::Response->new($scope, $send) ||
            return err('unable to get PAGI::Response object');
        

        #  Create new WebDyne  Request object, will pull filename from
        #  environment. 
        #
        my $html;
        my $html_fh=IO::String->new($html);
        my $r=WebDyne::Request::PAGI->new(select => $html_fh, document_root => $DOCUMENT_ROOT, document_default => $DOCUMENT_DEFAULT, scope=>$scope, req=>$req_or, res=>$res_or, 
            receive => $receive, send=> $send) ||
                return err('unable to create new WebDyne::Request::PAGI object: %s', 
                    $@ || errclr() || 'unknown error');
        debug("r: $r");

        
        #  Call handler and evaluate results
        #
        my $status=WebDyne->handler($r);
        debug("handler returned status: $status");


        #  Can close html file handle now
        #
        $html_fh->close();
        debug("html returned:\n$html");


        #  Present error if non 200 (success) status returned. Yes - there are other status codes but this is most
        #  common and quickest test, other 200 codes will fall through the if/else statements and still work
        #
        unless ($status == HTTP_OK) {
            
            
            #  OK. Most common match didn't happen. Is it an error ?
            #
            if (!defined($status) || ($status < 0) ||  is_error($status) || $html) {
        
            
                #  Something went wrong. Let's start working through it
                #
                if (($status eq HTTP_NOT_FOUND) && !(-f (my $fn=$r->filename()))) {
                
                    
                    #  If get here nothing found, send 404 error
                    #
                    debug("status: $status, fn:$fn, setting HTTP_NOT_FOUND");
                    $r->status(HTTP_NOT_FOUND);
                    my $error=errdump() || "File not found, status ($status)"; errclr();
                    $html=$r->err_html($status, $error)
                }
                elsif (is_error($status) ) {
                
                    #  Some other error besides 404
                    #
                    debug("returning custom error: $status");
                    $html=$r->custom_response($status) || errstr() ||
                        "Error $status with no content - try server error logs ?";
                    $r->content_type($WEBDYNE_CONTENT_TYPE_TEXT);
                    

                }
                else {
                
                    #  Weird non HTTP status code, something has gone wrong along way
                    #
                    debug('undefined status returned, looking for error handler');
                    my $error=errdump() || $@; errclr();
                    $error ||=  "Unexpected return status ($status) from handler";
                    debug("request handler status:$status, detected error: $error, calling err_html");
                    $r->status(HTTP_INTERNAL_SERVER_ERROR);
                    $html=$r->err_html($status, $error)

                }
                    
            }
            else {
            
                #  Not an error, but not HTTP_OK
                #
                debug("status: $status is not an error, proceeding");
                
            }

        }
        debug("final handler status: %s, content_type: %s, html:%s", $status, $r->content_type(), $html);
        
        
        #  If html defined set header content type unless already set during handler run
        #
        if ($html) {
            $r->content_type($WEBDYNE_CONTENT_TYPE_HTML) unless $r->content_type();
            return await $r->send($html || err);
       }
        
    }
    
}


sub handler_lifespan {

    return async sub {

        my ($scope, $receive, $send) = @_;
        while (1) {
            my $event_hr = await $receive->();
            if ($event_hr->{'type'} eq 'lifespan.startup') {
                print STDERR "[lifespan] WebDyne PAGI handler startup. DOCUMENT_ROOT: $DOCUMENT_ROOT, DOCUMENT_DEFAULT: $DOCUMENT_DEFAULT\n";
                await $send->({ type => 'lifespan.startup.complete' });
                
            }
            elsif ($event_hr->{'type'} eq 'lifespan.shutdown') {
                print STDERR "[lifespan] WebDyne PAGI handler shutdown.\n";
                await $send->({ type => 'lifespan.shutdown.complete' });
                last;
            }
        }
    }
}


sub normalize_dn {

    #  Normal dir, normally document_root
    #
    my $rel_dn=shift();
    my $abs_dn=File::Spec->rel2abs($rel_dn);
    $abs_dn =~ s{/$}{} unless $abs_dn eq '/';
    return $abs_dn;
    
}


sub init {

    #  Finalise DOCUMENT_ROOT. 
    #  flag wins over everything else
    #
    my %plack;
    my $plack_or=\%plack;
    my ($noindex_fg, $test_fg);


    #  Finalise DOCUMENT_ROOT. First try and get as last command line option or env or variable but --test
    #  flag wins over everything else
    #
    $DOCUMENT_ROOT=shift(@{$plack_or->{'argv'}}) ||
        $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT;
    #if ($test_fg || !$DOCUMENT_ROOT) {
    #    $DOCUMENT_ROOT=$test_fn;
    #}
    if ($test_fg) {
        $DOCUMENT_ROOT=$test_fn;
    }
    elsif(! $DOCUMENT_ROOT) {
        $DOCUMENT_ROOT=fastcwd();
    }
    $DOCUMENT_ROOT=&normalize_dn($DOCUMENT_ROOT);
    
    
    #  Indexing ? Do by default unless file specified as DOCUMENT_ROOT or --noindex spec'd etc.
    #
    unless (-f $DOCUMENT_ROOT || -f File::Spec->catfile($DOCUMENT_ROOT, $DOCUMENT_DEFAULT) || $noindex_fg) {

        #  Final check. Only do if directory
        #
        if (-d $DOCUMENT_ROOT) {
    
            #  We can do indexing
            #
            $DOCUMENT_DEFAULT=File::Spec->rel2abs(File::Spec->catfile($test_dn, $WEBDYNE_PSGI_INDEX));
            
        }
        
    }
    
    
    #  Read in local webdyne.conf.pl
    #
    #&local_constant_load($DOCUMENT_ROOT);
    
    
    #  Show error information by default
    #
    $WebDyne::WEBDYNE_ERROR_SHOW=1;
    $WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=1;
        
}

1;
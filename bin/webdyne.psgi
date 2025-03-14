#!/usr/bin/perl
#
#  This file is part of WebDyne::Request::PSGI.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
#
#  This is free software; you can redistribute it and/or modify it under
#  the same terms as the Perl 5 programming language system itself.
#
#  Full license text is available at:
#
#  <http://dev.perl.org/licenses/>
#
package WebDyne::Request::PSGI::Run;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);


#  External Modules
#
use HTTP::Status qw(RC_INTERNAL_SERVER_ERROR RC_NOT_FOUND HTTP_OK);
use IO::String;
use Data::Dumper;



#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Util;
use WebDyne::Request::PSGI;
use WebDyne::Request::PSGI::Constant;


#  Version information
#
$VERSION='1.002';


#  Let DOCUMENT ROOT be overridden if needed
#
$DOCUMENT_ROOT=pop(@ARGV) || $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT;


#  All done. Start endless loop if called from command line or return
#  handler code ref.
#
unless (caller) {
    require Plack::Runner;
    my $runner=Plack::Runner->new;
    $runner->parse_options(@ARGV);
    $runner->run(\&handler);
    exit 0;
}


#  Return handler code ref
#
\&handler;


#==================================================================================================


#  Start endless loop
#
sub handler {


    #  Get env
    #
    my $env_hr=shift();
    local *ENV=$env_hr;
    #$ENV{'DOCUMENT_ROOT'} ||= $DOCUMENT_ROOT;
    debug('in handler, env: %s', Dumper(\%ENV));


    #  Cache handler for a location
    #
    my ($handler, %handler);


    #  Create new PSGI Request object, will pull filename from
    #  environment. 
    #
    my $html;
    my $html_fh=IO::String->new($html);
    my $r=WebDyne::Request::PSGI->new(select => $html_fh, document_root => $DOCUMENT_ROOT) ||
        return err('unable to create new WebDyne::Request::PSGI object: %s', 
			$@ || errclr() || 'unknown error');
    debug("r: $r");


    #  Get handler
    #
    unless ($handler=$handler{my $location=$r->location()}) {
        my $handler_package=
            $r->dir_config('WebDyneHandler') || $ENV{'WebDyneHandler'};
        if ($handler_package) {
            local $SIG{'__DIE__'};
            unless (eval("require $handler_package")) {
                #  Didn't load - let Webdyne handle the error.
                $handler='WebDyne';
            }
            else {
                $handler=$handler{$location}=$handler_package;
            }
        }
        else {
            $handler=$handler{$location}='WebDyne';
        }
    }
    debug("calling handler: $handler");
    

    #  Call handler and evaluate results
    #
    my $status=eval {$handler->handler($r)} if $handler;
    debug("handler returned status: $status");


	#  Can close html file handle now
	#
    $html_fh->close();
    debug("html returned: $html");


	#  Present error if no status returned
	#
    if (!defined($status)) {
        debug('undefined status returned, looking for error handler');
        if (($status=$r->status) ne RC_INTERNAL_SERVER_ERROR) {
            my $error=errdump() || $@; errclr();
            debug("request handler status:$status, detected error: $error, calling err_html");
            $r->status(RC_INTERNAL_SERVER_ERROR),
            $html=$r->err_html($status, $error)
        }
        else {
            debug('status fall through !')
        }
    }
    elsif (($status < 0) && !(-f (my $fn=$r->filename()))) {
        debug("status: $status, fn:$fn, setting RC_NOT_FOUND");
        $r->status(RC_NOT_FOUND);
		my $error=errdump() || "File '$fn' not found, status ($status)"; errclr();
		$html=$r->err_html($status, $error)
        #warn("file $fn not found") if $WEBDYNE_FASTCGI_WARN_ON_ERROR;
    }
    elsif ($status < 0) {
        debug("status: $status, setting RC_INTERNAL_SERVER_ERROR");
        $r->status($status=RC_INTERNAL_SERVER_ERROR),
        $html=$r->err_html($status, "Unexpected return status ($status) from handler $handler")
	}
	elsif (($status eq RC_INTERNAL_SERVER_ERROR) && !$html) {
	    $html=$r->custom_response($status) ||
	        "Error $status with no content - try server error logs ?";
    }
    debug("final handler status is $status, html:$html");


	#  If html defined set header
	#
	$r->content_type($WEBDYNE_CONTENT_TYPE_HTML) if $html;

	
	#  Return structure
	#
	my @return=(
        $r->status() || RC_INTERNAL_SERVER_ERROR,
        [
			%{$r->headers_out()}
		],
        [
			$html 
		]
	);


	#  Finished with response handler now
	#
	$r->DESTROY();


	#  And return
	#
	debug('return %s', Dumper(\@return));
	return \@return;


}


sub error {

	#  Get and return error string as last resort. Test function not used 
	#  in main handler.
	#
	my $error=sprintf(shift(), @_) ||
		'Unknown error';

	#  Basic error response
	#
    return [
        RC_INTERNAL_SERVER_ERROR,
        ['Content-Type' => 'text/plain'],
        [join($/,
			'Internal Server Error:',
			undef, 
			$error
		)]
    ];

}
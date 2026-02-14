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
package WebDyne::PSGI;


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
use File::Basename;
use File::Spec;


#  PSGI modules
#
use Plack::Request;
use Plack::Response;


#  WebDyne Modules
#
use WebDyne;
use WebDyne::Constant;
use WebDyne::Util;
use WebDyne::PSGI::Constant;
use WebDyne::Request::PSGI;


#  Vars. API file name cache
#
our (%API_fn);


#  Environment
#
my %env_config=(
    %{$WEBDYNE_PSGI_ENV_SET}, 
    (map { $_=>$ENV{$_}  } (
        grep { defined($ENV{$_}) }
        qw(DOCUMENT_DEFAULT DOCUMENT_ROOT),
        @{$WEBDYNE_PSGI_ENV_KEEP},
        grep {/WEBDYNE/i} keys %ENV
    ))
);


#  Version information
#
$VERSION='2.075';


#==================================================================================================

sub new {


    #  Get options
    #
    my ($class, %opt)=@_;
    
    
    #  Test ?
    #
    if ($opt{'test'}) {
        $opt{'root'}=$WEBDYNE_DEFAULT_TEST_FN;
    }
    
    
    #  Indexing. 1 for enable with internal, string for some other indexing file
    #
    if ($opt{'index'} eq '1') {
        $opt{'index'}=$WEBDYNE_DEFAULT_INDEX_FN;
    }
    

    #  Fix document root
    #
    $opt{'root'}=File::Spec->rel2abs($opt{'root'});
    

    #  Done
    #
    return bless(\%opt, $class);
    
}


sub to_app {


    #  Self ref
    #
    my $self=shift();


    #  Dispatch code ref
    #
    my $app_cr=sub { $self->handler(@_) };
    

    #  Done
    #
    return $app_cr;
    
}


#  Actual Plack handler
#
sub handler {


    #  Get env
    #
    my ($self, $env_hr, @param)=@_;
    local %ENV=(%env_config, %{$env_hr});
    debug('in handler, env: %s, param:%s', Dumper(\%ENV, \@param));
    
    
    #  Create new PSGI Request object, will pull filename from
    #  environment. 
    #
    my $html;
    my $html_fh=IO::String->new($html);
    my $r=WebDyne::Request::PSGI->new(select => $html_fh, document_root => $self->{'root'}, document_default => $self->{'index'}, uri=>$ENV{'PATH_INFO'}, env=>$env_hr, @param) ||
        return err('unable to create new WebDyne::Request::PSGI object: %s', 
    			$@ || errclr() || 'unknown error');
    debug("r: $r");
    
    
    #  Get handler
    #
    my $handler=$self->{'handler'} ||= 'WebDyne';


    #  Call handler and evaluate results
    #
    my $status=eval {$handler->handler($r)};
    debug("handler returned status: $status");


    #  Can close html file handle now
    #
    $html_fh->close();
    debug("html returned: $html");


	#  Present error if non 200 (success) status returned. Yes - there are other status codes but this is most
	#  common and quickest test, other 200 codes will fall through the if/else statements and still work
	#
	unless ($status == HTTP_OK) {
	    
	    
	    #  OK. Most common match didn't happen. Is it an error ?
	    #
	    debug('status: %s is not HTTP_OK, branching', $status);
 	    if (!defined($status) || ($status < 0) ||  is_error($status) || !$html) {
	
	    
            #  Something went wrong. Let's start working through it
            #
            if (($status eq HTTP_NOT_FOUND) && !(-f (my $fn=$r->filename()))) {

            
                #  We couldn't find file but this might be an API request. Go back through
                #  file paths looking for a file that matches the apu request, e.g. if URI
                #  is /api/user/42 go back looking for /api/user.psp or /api.psp in the treet
                #
                debug("status: $status, fn: $fn");
                my $document_root=$r->document_root;
                if ($WEBDYNE_API_ENABLE) {
                    debug("status: $status, fn:$fn (%s), looking for API match", $r->filename());
                    #(my $api_dn=$fn)=~s/^${document_root}//;
                    (my $api_dn=$ENV{'PATH_INFO'})=~s/^${document_root}//;
                    my @api_dn=grep {$_} File::Spec::Unix->splitdir($api_dn);
                    my @api_fn;
                    while (my $dn=shift @api_dn) {
                        push @api_fn, $dn;
                        my $api_fn=File::Spec->catfile($document_root, @api_fn) . WEBDYNE_PSP_EXT;
                        debug("check $api_fn");
                        #  Check of outside docroot
                        last if (index($api_fn, $document_root) !=0);
                        if ($API_fn{$api_fn} || (-f $api_fn)) {
                            debug("found api file name: $api_fn, %s, dispatching", Dumper(\%API_fn));
                            $API_fn{$api_fn}++; # Cache so not stat()ing on file system
                            return &handler($env_hr, filename=>$api_fn);
                        }
                    }
                }
                
                
                #  If get here nothing found, send 404 error
                #
                debug("status: $status, fn:$fn, setting HTTP_NOT_FOUND");
                $r->status(HTTP_NOT_FOUND);
                my $error=errdump() || "File not found, status ($status)"; errclr();
                $html=$r->err_html($status, $error)
            }
            elsif (is_error($status)) {
            
                #  Some other error besides 404
                #
                debug("returning custom error: $status");
                $r->status($status);
                $html=$r->custom_response($status) || errstr() || do {
                     $r->content_type($WEBDYNE_CONTENT_TYPE_TEXT);
                    "Error $status with no content - try server error logs ?";
                };
            }
            else {
            
                #  Weird non HTTP status code, something has gone wrong along way
                #
                debug('undefined status returned, looking for error handler');
                my $error=errdump() || $@; errclr();
                $error ||=  "Unexpected return status ($status) from handler $handler";
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
    $r->content_type($WEBDYNE_CONTENT_TYPE_HTML) 
        if ($html && !$r->content_type());

    
    #  Return structure
    #
    my @return=(
    $r->status() || HTTP_INTERNAL_SERVER_ERROR,
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
    my @error=@_;
    my $error=sprintf(shift(), @error) ||
            'Unknown error';

    #  Basic error response
    #
    return [
        HTTP_INTERNAL_SERVER_ERROR,
        ['Content-Type' => 'text/plain'],
        [join($/,
	    'Internal Server Error:',
	    undef, 
	    $error
        )]
    ];

}



__END__


    
sub to_app {


    #  Self ref
    #
    my $self=shift();


    #  Dispatch table
    #
    my %handler=(
        http        => sub { shift()->handler_http(@_) },
        sse         => sub { shift()->handler_sse(@_) },
        ws          => sub { shift()->handler_ws(@_) },
        lifespan    => sub { shift()->handler_lifespan(@_) }
    );
        

    # Main application
    #
    my $app_cr = async sub {

        my ($scope, $receive, $send) = @_;
        if (my $handler_cr=$handler{my $type=$scope->{type}}) {
            #  Supported type, dispatch
            #
            return await $handler_cr->($self, $scope, $receive, $send)->($scope, $receive, $send);
        }
        else {
            #  Unsupported type
            #
            die "Unsupported scope type: $type";
        }

    };
    
    
    #  Done
    #
    return $app_cr;
    
}




sub handler_http {

    
    #  Self ref contains things like document_root, dcoument_default
    #
    my $self=shift();


    #  Return async sub for handling WebDyne requests
    #
    return set_subname('handler_http_anon', async sub {


        #  Get request
        #
        my ($scope, $receive, $send)=@_;
        debug('in handler, scope:%s receive:%s, send:%s', Dumper($scope, $receive, $send));
        

        #  Restrict local env
        #
        local %ENV=(
            %{$WEBDYNE_PAGI_ENV_SET}, 
            (map { $_=>$ENV{$_}  } (
                grep { defined($ENV{$_}) }
                qw(DOCUMENT_DEFAULT DOCUMENT_ROOT),
                @{$WEBDYNE_PAGI_ENV_KEEP},
                grep {/WEBDYNE/i} keys %ENV
            ))
        );

        
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
        my $r=WebDyne::Request::PAGI->new(select => $html_fh, document_root => $self->{'root'}, document_default => $self->{'index'}, scope=>$scope, req=>$req_or, res=>$res_or, 
            receive => $receive, send=> $send) ||
                return err('unable to create new WebDyne::Request::PAGI object: %s', 
                    $@ || errclr() || 'unknown error');
        debug("r: $r");

        
        #  Call handler and evaluate results
        #
        my $status=WebDyne->handler($r);
        debug("handler returned status: $status");
        $r->status($status);


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
            debug('status: %s is not HTTP_OK, branching', $status);
            if (!defined($status) || ($status < 0) ||  is_error($status) || !$html) {
        
            
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
                    $r->status($status);
                    $html=$r->custom_response($status) || errstr() || do {
                        $r->content_type($WEBDYNE_CONTENT_TYPE_TEXT);
                        "Error: $status with no content - try server error logs ?";
                    };

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
        
        
        #  Send headers unless already sent
        #
        my $headers_ar=$r->headers_out->psgi_flatten_without_sort();
        debug('sending headers: %s', Dumper($headers_ar));
        for (my $i=0; $i<@{$headers_ar}; $i+=2) {
            my ($header, $value)=@{$headers_ar}[$i, $i+1];
            $r->header_try($header => $value);
        }
        
        
        #  If html defined set header content type unless already set during handler run and send
        #
        if ($html) {
            debug('sending html to client via await()');
            $r->content_type_try($WEBDYNE_CONTENT_TYPE_HTML);
            return await $r->send($html || err);
       }
        
    })
    
}


sub handler_lifespan {

    my $self=shift();
    
    return set_subname('handler_lifespan_anon', async sub {

        my ($scope, $receive, $send) = @_;
        while (1) {
            my $event_hr = await $receive->();
            if ($event_hr->{'type'} eq 'lifespan.startup') {
                printf STDERR "[lifespan] WebDyne PAGI handler startup. DOCUMENT_ROOT: %s, DOCUMENT_DEFAULT: %s\n", $self->{'root'}, basename($self->{'index'});
                await $send->({ type => 'lifespan.startup.complete' });
                
            }
            elsif ($event_hr->{'type'} eq 'lifespan.shutdown') {
                print STDERR "[lifespan] WebDyne PAGI handler shutdown.\n";
                await $send->({ type => 'lifespan.shutdown.complete' });
                last;
            }
        }
    })
}


sub normalize_dn {

    #  Normal dir, normally document_root
    #
    my $rel_dn=shift();
    my $abs_dn=File::Spec->rel2abs($rel_dn);
    $abs_dn =~ s{/$}{} unless $abs_dn eq '/';
    return $abs_dn;
    
}

1;
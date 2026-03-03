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

package WebDyne::Request::PSGI;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use File::Spec;
use File::Spec::Unix;
use HTTP::Status qw(status_message HTTP_OK HTTP_NOT_FOUND HTTP_FOUND);
use URI;
use Data::Dumper;
use Plack::Request;
use Plack::Response;


#  WebDyne modules
#
use WebDyne::Util;
use WebDyne::Constant;
use WebDyne::PSGI::Constant;
use WebDyne::Request::Common qw(handler_methods_all handler_methods_check);


#  Inheritance
#
use WebDyne::Request::Fake;
@ISA=qw(WebDyne::Request::Fake);


#  Version information
#
$VERSION='2.075';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Init
#
&init() unless defined(&method);


#  All done. Positive return
#
1;


#==================================================================================================


sub init {

    #  Setup pass through methods
    #
    my %method=(
        req => {
            accept_encoding     => undef,
            accept_language     => undef,
            accept              => undef,
            args                => undef,
            as_string           => undef,
            authority           => undef,
            authorization       => undef,
            auth_type           => undef,
            base                => 'base',
            base_url            => 'base',
            body_handle         => 'input',
            #body                => sub { my $r=shift(); if (my $input_or=$r->input) { unless (exists $r->{'body'}) { $input_or->read($r->{'body'}, $r->content_length()) }; return $r->{'body'} } },
            body                => undef,
            cache_control       => undef,
            charset             => undef,
            cleanup_register    => undef,
            client_address      => 'address',
            content             => 'body',
            content_encoding    => 'content_encoding',
            #content_length      => 'content_length',
            #content_type        => 'content_type',
            content_length      => undef,
            content_type        => undef,
            cookies             => 'cookies',
            cookie              => 'cookies',
            custom_response     => undef,
            cwd                 => undef,
            dir_config          => undef,
            document_root       => undef,
            env                 => 'env',
            etag                => undef,
            filename            => undef,
            finalize            => undef,
            finfo               => undef,
            form_parameters     => 'body_parameters',
            forwarded_for       => undef,
            fragment            => undef,
            handler             => undef,
            header              => sub { shift()->{'req'}->headers->header(@_) },
            header_only         => undef,
            headers_in          => undef,
            headers_out         => undef,
            hostname            => undef,
            host                => undef,
            https               => undef,
            http_version        => 'protocol',
            id                  => sub { shift()->env->{'psgi.request_id'} },
            if_modified_since   => undef,
            if_none_match       => undef,
            input               => sub { shift()->env->{'psgi.input'} },
            is_ajax             => undef,
            is_main             => undef,
            location            => undef,
            log_error           => undef,
            lookup_file         => undef,
            lookup_uri          => undef,
            main                => undef,
            media_type          => undef,
            method              => 'method',
            mtime               => undef,
            multipart_parameters=> 'body_parameters',
            next                => undef,
            notes               => undef,
            origin              => undef,
            output_filters      => undef,
            path_info           => 'path_info',
            path_parameters     => undef,
            path                => 'path_info',
            pool                => undef,
            preferred_charset   => undef,
            preferred_encoding  => undef,
            preferred_language  => undef,
            preferred_media_type=> undef,
            prev                => undef,
            print               => undef,
            protocol            => 'protocol',
            query_parameters    => 'query_parameters',
            query_string        => 'query_string',
            redirect            => undef,
            referer             => 'referer',
            register_cleanup    => undef,
            remote_address      => 'address',
            remote_host         => 'remote_host',
            remote_port         => undef,
            remote_user         => 'user',
            request_time        => sub { shift()->env->{'psgi.start_time'} },
            route               => undef,
            run                 => undef,
            scheme              => 'scheme',
            script_name         => 'script_name',
            secure              => 'secure',
            sendfile            => undef,
            send_http_header    => undef,
            server_name         => undef,
            server_port         => undef,
            session_id          => undef,
            session             => undef,
            set_handlers        => undef,
            status_line         => undef,
            status              => undef,
            unparsed_uri        => 'uri',
            uploads             => 'uploads',
            uri                 => 'uri',
            url                 => 'uri',
            user_agent          => 'user_agent',
            user                => undef,
            write               => undef,
        },
        res => {(
           #status headers body header content_typee content_length content_encoding redirect location cookies finalize to_app
        )},
            
    );
    my %method_check;
    foreach my $handler (qw(req res)) {
        while (my ($method, $dispatch)=each %{$method{$handler}}) {
            debug("method: $method");
            $method_check{$method}++;
            if (defined(*{sprintf('%s::%s', __PACKAGE__, $method)}{'CODE'})) {
                #  Do nothing, defined here
                #
                debug("skip $method, defined in this package");
            }
            elsif (!defined($dispatch)) {
                #  Do nothing, will fall through to Fake
                #
                debug("skip $method, will inherit from Fake");
            }
            elsif (ref($dispatch) eq 'CODE') {
                #  Turn into method
                #
                debug("setting method: $method to code ref: $dispatch");
                *{$method}=$dispatch;
            }
            else {
                #  Plack method
                #
                debug("setting method: $method to $handler: $dispatch");
                *{$method}=sub { shift()->{'req'}->$dispatch(@_) };
            }
        }
    }


    #  Done, do runtime check and return, will warn if we have missed anything
    #
    return handler_methods_check(__PACKAGE__, \%method_check);
    
}


sub new {


    #  New PSGI request
    #
    my ($class, %r)=@_;
    debug("$class, r: %s, calller:%s", Dumper(\%r, [caller(0)]));
    

    #  Get PSGI env var
    #
    my $env_hr=$r{'env'} ||
        return err('no PSGI env supplied');
    

    #  Try to figure out filename user wants
    #
    unless ($r{'filename'}) {
    
    
        #  Not supplied - need to work out
        #
        debug('filename not supplied, determining from request');

    
        #  Iterate through options. If *not* supplied by SCRIPT_FILENAME keep going.
        #
        my $fn;
        unless (($fn=$env_hr->{'SCRIPT_FILENAME'}) && !$r{'uri'}) {
        
        
            #  Need to calc from document root in PSGI environment
            #
            debug('not supplied in SCRIPT_FILENAME or uri param. calculating');
            if (my $dn=($r{'document_root'} || $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT)) {
            
                #  Get from URI and location
                #
                my $uri=$r{'uri'} || $env_hr->{'PATH_INFO'};
                my @split=split(m{/+}, $uri);
                debug("uri: $uri, split: %s", Dumper(\@split));
                $fn=File::Spec->catfile($dn, split(m{/+}, $uri)); #/
                debug("fn: $fn from dn: $dn, uri: $uri");
                
            }
            
            
            #  Need to add default psp file ?
            #
            #unless ($fn=~/\.psp$/) { # fastest
            unless ($fn=~WEBDYNE_PSP_EXT_RE) { # fastest

                #  Is it a directory that exists ? Only append default document if that is the case, else let the api code
                #  handle it
                #
                debug("no .psp extenstion on fn: $fn, looking at options");
                if  (($fn=~/\/$/) || ((-d $fn) || !$fn)) {
                    
            
                    #  Append default doc to path, which appears at moment to be a directory ?
                    #
                    my $document_default=$r{'document_default'} || $DOCUMENT_DEFAULT;
                    debug("appending document default $document_default to fn:$fn");
                    
                    #  If absolute path just use it
                    #
                    if (File::Spec->file_name_is_absolute($document_default)) {
                    
                        #  Yep - absolute path
                        #
                        $fn=$document_default
                    }
                    else {
                    
                        #  Otherwise append to existing path
                        #
                        $fn=File::Spec->catfile($fn, split m{/+}, $document_default); #/
                    }
                }
                else {
                    
                    #  Not .psp file, do not want
                    #
                    debug("fn: $fn does not end with /, leaving undef");
                    $fn=undef;
                }
            }
        }


        #  Final sanity check
        #
        debug("final fn: $fn");
        $r{'filename'}=$fn; 
        
    }
    
    
    #  Setup request and response handlers
    #
    #$r{'req'}=Plack::Request->new($env_hr);
    #$r{'res'}=Plack::Response->new(HTTP_OK);
    
    
    #  Finished, pass back
    #
    return bless \%r, $class;

}

sub body {

    my $r=shift(); 
    if ((my $input_or=$r->input) && $r->content_length()) { 
        unless (exists $r->{'body'}) {
            $input_or->read($r->{'body'}, $r->content_length()) 
        }
        return $r->{'body'} 
    } 
}


sub headers_in {
    my $r=shift();
    if (@_) {
        return $r->{'req'}->headers()->header(@_);
    }
    else {
        return $r->{'req'}->headers();
    }
}


__END__

sub new_from_filename {

    #  Test method, not used
    #
    my ($class, $fn, $select_fh)=@_;
    my %r=(filename=>$fn, select=>$select_fh, env=>\%ENV);
    return bless(\%r, $class);
    
}


sub status1 {

    #  PSGI doesn't return the status code when setting, so code like
    #  return $r->status(500) doesn't work.
    #
    #my ($r, $status)=@_;
    #die $status;
    #$#_ ? $r->{'res'}->status($status) : ($status=$r->{'res'}->status());
    #@_ ? $r->res->status=
    #$r->{'res'}->status($r->{'status'}=shift()) if @_;
    #return $r->{'status'}
    #return $shift
    my $r=shift();
    return $r->{'res'}->status(@_);
    
}

sub status0 {

    #  PSGI doesn't return the status code when setting, so code like
    #  return $r->status(500) doesn't work.
    #
    #my ($r, $status)=@_;
    my $r=shift();
    #$#_ ? $r->{'res'}->status($status) : ($status=$r->{'res'}->status());
    #@_ ? $r->res->status=
    $r->{'res'}->status($r->{'status'}=shift()) if @_;
    return $r->{'status'}
    #return $status;
    
}

__END__

sub content_type {

    my $r=shift();
    my $hr=$r->headers_out();
    #@_ ? $r->headers_out()->{'Content-Type'}=shift() : $r->SUPER::content_type();
    return @_ ? $r->headers_out()->{'Content-Type'}=shift() : ($r->headers_out()->{'Content-Type'} || $ENV{'CONTENT_TYPE'});

}


sub custom_response0 {

    my ($r, $status)=(shift(), shift());
    while ($r->prev) {$r=$r->prev}
    debug("in custom response, status $status");
    @_ ? $r->{'custom_response'}{$status}=shift() : $r->{'custom_response'}{$status};

}


sub filename {

    my $r=shift();
    @_ ? $r->{'filename'}=shift() : $r->{'filename'};

}


sub header_only {

    (shift()->method() eq 'HEAD') ? 1 : 0 

}


sub headers_in {
    my $r=shift();
    return $r->headers();
}


sub headers_out {

    my $r=shift();
    return WebDyne::Request::Fake::headers($r, 'headers_out', @_);

}    


sub location0 {


    #  Equiv to Apache::RequestUtil->location;
    #
    my $r=shift();
    debug("r: $r, caller: %s", Dumper([caller(0)]));
    my $location;
    my $constant_hr=$WEBDYNE_DIR_CONFIG;
    my $constant_server_hr;
    #if (my $server=$Dir_config_env{'WebDyneServer'} || $ENV{'SERVER_NAME'}) {
    if (my $server=$ENV{'WebDyneServer'} || $ENV{'SERVER_NAME'}) {
        $constant_server_hr=$constant_hr->{$server} if exists($constant_hr->{$server})
    }
    #if ($Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'}) {
    if ($location=$r->{'location'}) {
        return $location;
    }
    elsif ($ENV{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'}) {

        #  APPL_MD_PATH is IIS virtual dir. If that or a fixed location set use it.
        #
        #$location=$Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'};
        $location=$ENV{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'};
    }
    elsif (my $uri_path=join('', grep {$_} @ENV{qw(SCRIPT_NAME PATH_INFO)})) {
        
        #  Strip file name
        #
        $uri_path=~s{[^/]+\Q@{[WEBDYNE_PSP_EXT]}\E$}{}x; #\
        debug("uri_path: $uri_path");
        my @location=('/', grep {$_} File::Spec::Unix->splitdir($uri_path));
        
        #  Start iterating through directories
        #
        while ($location=File::Spec::Unix->catdir(@location)) {
            debug("location: $location");
            last if exists($constant_hr->{$location}) || exists($constant_server_hr->{$location});
            $location.='/' unless ($location eq '/');
            last if exists($constant_hr->{$location}) || exists($constant_server_hr->{$location});
            pop @location;
        }
    }
    else {
        
        #  Actually mod_perl spec says location blank if not positively given - don't default to '/'
        #
        #$location=File::Spec::Unix->rootdir();
    }
    
    #  
    #
    return $location;

}


sub log_error {

    my $r=shift();
    warn(@_) if $WEBDYNE_PSGI_WARN_ON_ERROR;

}


sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child;
    if ($fn!~WEBDYNE_PSP_EXT_RE) { # fastest


        #  Static file
        #
        require WebDyne::Request::PSGI::Static;
        $r_child=WebDyne::Request::PSGI::Static->new(filename => $fn, prev => $r) ||
            return err();

    }
    else {


        #  Subrequest
        #
        $r_child=ref($r)->new(filename => $fn, prev => $r) || return err();

    }

    #  Return child
    #
    return $r_child;

}


sub lookup_uri {

    my ($r, $uri)=@_;
    ref($r)->new(uri => $uri, prev => $r) || return err();

}


sub redirect {

    my ($r, $location)=@_;
    $r->status(HTTP_FOUND);
    $r->headers_out('Location' => $location);
    return HTTP_FOUND;

}


sub run {

    my ($r, $self)=@_;
    debug("self: $self, r:$r");
    if (-f $r->{'filename'}) {
        debug('file is %s', $r->{'filename'});
        return ref($self)->handler($r);
    }
    else {
        debug("file not found !");
        $r->status(HTTP_NOT_FOUND);
        $r->send_error_message;
        return HTTP_NOT_FOUND;
    }

}


sub send_error_response {

    my $r=shift();
    my $status=$r->status();
    debug("in send error response, status $status");
    if (my $message=$r->custom_response($status)) {

        #  We have a custom response - send it
        #
        $r->print($message);

    }
    else {

        #  Create an generic error message
        #
        $r->print(
            $r->err_html(
                $status,
                status_message($status)
            ));
    }
}


sub err_html {

    #  Very basic HTML error messages for file not found and similar
    #
    my ($r, $status, $message)=@_;
    require WebDyne::HTML::Tiny;
    my $html_or=WebDyne::HTML::Tiny->new( mode=>$WEBDYNE_HTML_TINY_MODE, r=>$r ) ||
        return err();
    my $error;
    my @message=(
        $html_or->start_html($error=sprintf("%s Error $status", __PACKAGE__)),
        $html_or->h1($error),
        $html_or->hr(),
        $html_or->em(status_message($status) || 'Unknown Error'), $html_or->br(), $html_or->br(),
        $html_or->pre(
            sprintf("The requested URI '%s' generated error:\n\n$message", $r->uri)
        ),
        $html_or->end_html()
    );
    return join('', @message);

}


sub send_http_header {

    #  Stub
    
}


#package My::Module;

#use strict;
#use warnings;
use B ();

if (0) {
    no strict 'refs';
    no warnings qw(redefine);
    for my $symbol (keys %{"WebDyne::Request::PSGI::"}) {
        next if $symbol=~/^WEBDYNE_/;
        next if $symbol=~/^MOD_PERL/;
        next if $symbol=~/^MP2/;
        next if $symbol=~/^__/;
        next if $symbol=~/^debug/;
        next if $symbol=~/^Dumper/;
        warn "$symbol\n";
        #die $symbol;

        my $fullname = "WebDyne::Request::PSGI::$symbol";

        next unless defined &{$fullname};
        next if $symbol =~ /^(BEGIN|import|can|DESTROY)$/;

        my $orig = \&{$fullname};

        *{$fullname} = sub {
            print STDERR "Calling $symbol from WebDyne::Request::PSGI\n";
            goto &$orig;
        };
    }
}

1;

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

package WebDyne::Request::PAGI;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use File::Spec::Unix;
use HTTP::Status qw(status_message HTTP_OK HTTP_NOT_FOUND HTTP_FOUND);
use URI;
use Data::Dumper;
use PAGI::Request;
$Data::Dumper::Indent=1;
use Cwd qw(fastcwd);


#  WebDyne modules
#
use WebDyne::Request::PSGI;
use WebDyne::Request::PSGI::Constant;
use WebDyne::Util;
use WebDyne::Constant;


#  Inheritance
#
use WebDyne::Request::Fake;
#@ISA=qw(PAGI::Request WebDyne::Request::PSGI);
@ISA=qw(WebDyne::Request::Fake);


#  Version information
#
$VERSION='2.075';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Save local copy of environment for ref by Dir_config handler. ENV is reset for each request,
#  so must use a snapshot for simulating r->dir_config
#
my %Dir_config_env=%{$WEBDYNE_PSGI_ENV_SET}, (map { $_=>$ENV{$_} } (
    qw(DOCUMENT_DEFAULT DOCUMENT_ROOT),
    @{$WEBDYNE_PSGI_ENV_KEEP},
    grep {/WebDyne/i} keys %ENV
));


#  Setup pass through methods
#
my %method=(
    req => [qw(
        method path raw_path query_string scheme host http_version client content_type content_length raw 
        header header_all headers
        query_params query_param raw_query_param
        path_params path_param
        cookies cookie
        body_stream body text json form_params form_param raw_form_params raw_form_param
        uploads upload upload_all
        is_get is_post_is_put is_patch is_delete is_head is_options is_json is_form is_multipart accepts preferred_type
        connection is_connection is_disconnected disconnect_reason on_disconnect disconnect_future
        bearer_token basic_auth
        stash state
   )], 
   res => [qw(
        status status_try header headers header_try content_type content_type_try cookie delete_cookie stash is_sent has_status has_header has_content_type cors
        text html json redirect empty send send_raw stream send_file
   )],
   sse => [
   ],
   ws  => [
   ]
        
);
my %method_req; @method_req{@{$method{'req'}}}=();
my %method_all=map {$_=>1} grep { exists $method_req{$_} } @{$method{'res'}};
foreach my $handler (qw(req res sse ws)) {
    *{$handler}=sub {
        return @_ ? $_[0]->{$handler}=$_[1] : $_[0]->{$handler};
    };
    foreach my $method (@{$method{$handler}}) {
        my $method_pagi=$method;
        if ($method_all{$method}) {
            my $inout=($handler eq 'req') ? 'in' : 'out';
            $method_pagi.="_${inout}";
        }
        unless (__PACKAGE__->can($method_pagi)) {
            *{$method_pagi}=sub {
                return @_ ? shift()->{$handler}->$method(@_) : shift()->{$handler}->$method();
            }
        }
        else {
            debug("skip $method_pagi");
        }
    }
}
            

#  All done. Positive return
#
1;


#==================================================================================================


sub new {

    my ($class, %r)=@_;
    unless ($r{'filename'}) {

        my $fn;
        if (my $dn=($r{'document_root'} || $ENV{'DOCUMENT_ROOT'} || $Dir_config_env{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT || fastcwd())) {
        
            #  Get from URI and location
            #
            my $uri=$r{'req'}->path();
            debug("uri: $uri");
            $fn=File::Spec->catfile($dn, split m{/+}, $uri); #/
            debug("fn: $fn from dn: $dn, uri: $uri");
            
        }
            
        #  Need to add default psp file ?
        #
        unless ($fn=~WEBDYNE_PSP_EXT_RE) { # fastest

            #  Is it a directory that exists ? Only append default document if that is the case, else let the api code
            #  handle it
            #
            if  ((-d $fn) || !$fn) {
                
        
                #  Append default doc to path, which appears at moment to be a directory ?
                #
                my $document_default=$r{'document_default'} || $Dir_config_env{'DOCUMENT_DEFAULT'} || $DOCUMENT_DEFAULT;
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
                $fn=undef;
            }
        }


        #  Final sanity check
        #
        debug("final fn: $fn");
        $r{'filename'}=$fn; 
        
    }
    
    
    #  Finished, pass back
    #
    return bless \%r, $class;
        
}


sub path_info {
    shift()->path()
}


sub protocol {
    shift()->http_version()
}


sub user {
    #  Stub
}


sub content_encoding {
    #  Stub
}


sub header_only {
    return (shift()->method eq 'HEAD')
}


sub headers_in {
    my $r=shift();
    my $headers_hr=$r->{'req'}->headers();
    use HTTP::Headers::Fast;
    return HTTP::Headers::Fast->new($headers_hr->flatten());
}

sub headers_out {
    my $r=shift();
    my $headers_ar=$r->{'res'}->headers();
    use HTTP::Headers::Fast;
    return HTTP::Headers::Fast->new(@{$headers_ar});
}


sub content_type {

    my $r=shift();
    debug("$r content_type: %s", Dumper(\@_));
    return @_ ? $r->{'res'}->content_type(@_) : $r->{'res'}->content_type();

}

sub header {

    my ($r, $header, @value)=@_;
    debug("$r header: $header: %s", Dumper(\@value));
    return @value ? $r->{'res'}->header($header, @value) : $r->{'req'}->header($header);

}

sub res0 {
    shift()->{'res'};
}

sub req0 {
    shift()->{'req'};
}

sub sse0 {
    shift()->{'sse'};
}

sub ws0 {
    shift()->{'ws'};
}


__END__

sub headers_out0 {
    my $r=shift();
    return $r->{'res'}->headers();
}

sub send_http_header0 {
    
}

sub status0 {

    my $r=shift();
    debug("$r status: %s", Dumper(\@_));
    return @_ ? $r->{'res'}->status(@_) : $r->{'res'}->status();

}

#no warnings qw(once);
#*status=\&res;
#*content_type=\&res;

sub res0 {

    my $r=shift();
    my $method=(caller(0))[3];
    if ($method eq 'res') {
        return $r->{'res'}
    }
    else {
        return @_ ? $r->{'res'}->$method(@_) : $r->{'res'}->$method();
    }
    
}

sub send0 {

    my $r=shift();
    debug("$r send: %s", Dumper(\@_));
    return @_ ? $r->{'res'}->send(@_) : $r->{'res'}->send();

}


sub location0 {
    return shift()->WebDyne::Request::Fake::location(@_);
}

sub dir_config0 {
    return shift()->WebDyne::Request::Fake::dir_config(@_);
}

sub cwd0 {
    return shift()->WebDyne::Request::Fake::cwd(@_);
}

sub filename0 {
    return shift()->{'filename'};
}

sub content_type0 {
    return shift()->{'res'}->content_type(@_);
}

sub send0 {
    my ($r, $self)=@_;
    $r->{'res'}->send(@_);
}

sub send0 {
    my $r=shift();
    $r->{'res'}->send(@_);
}

sub uri0 {
    my $self = shift;
    #return Dumper($self);

    my $base = $self->_uri_base($self->{'scope'});

    # We have to escape back PATH_INFO in case they include stuff like
    # ? or # so that the URI parser won't be tricked. However we should
    # preserve '/' since encoding them into %2f doesn't make sense.
    # This means when a request like /foo%2fbar comes in, we recognize
    # it as /foo/bar which is not ideal, but that's how the PSGI PATH_INFO
    # spec goes and we can't do anything about it. See PSGI::FAQ for details.

    # See RFC 3986 before modifying.
    my $path_escape_class = q{^/;:@&=A-Za-z0-9\$_.+!*'(),-};

    my $path = URI::Escape::uri_escape($self->path_info || '', $path_escape_class);
    $path .= '?' . $self->query_string()
        if defined $self->query_string() && $self->query_string() ne '';

    $base =~ s!/$!! if $path =~ m!^/!;

    return URI->new($base . $path)->canonical;
}

sub base {
    my $self = shift;
    URI->new($self->_uri_base)->canonical;
}

use Data::Dumper;
sub _uri_base0 {
    my $self = shift;
    debug("self: $self, %s", Dumper($self));
    my $server_ar=$self->{'server'};
    my $scheme=$self->scheme() || 'http';
    my $uri=sprintf('%s://%s:%s', $scheme, @{$server_ar});
    return $uri;
}

sub _uri_base {
    my ($self, $scope_hr) = @_;
    debug("self: $self, scope: $scope_hr %s", Dumper($scope_hr));
    my $server_ar=$scope_hr->{'server'};
    my $scheme=$scope_hr->{'scheme'} || 'http';
    debug("server_ar: %s, scheme: $scheme", Dumper($server_ar));
    my $uri=sprintf('%s://%s:%s', $scheme, @{$server_ar});
    return $uri;
}

__END__

use Future::AsyncAwait;
use Future::IO;



async sub watch_sse_disconnect {
    my ($receive) = @_;

    while (1) {
        my $event = await $receive->();
        return $event if $event->{type} eq 'sse.disconnect';
    }
}



sub  send1 {

    my ($self)=@_;

    #my ($scope, $receive, $send) = @_;
    my $send=$self->{'send'};
    my $receive=$self->{'receive'};
    debug("$self send: $send");


    $send->({
        type    => 'sse.start',
        status  => 200,
        headers => [ [ 'content-type', 'text/event-stream' ] ],
    });
    
    #my $disconnect = Future->wait_any(watch_sse_disconnect($receive));
    while (1) {

        #last if $disconnect->is_ready;
        #await Future::IO->sleep(2);
        sleep (2);
        debug('send');
        $send->({ type => 'sse.send', data => scalar localtime  });
        #await $send->({ type => 'sse.send', data => Dumper($scope)  });
    }
    debug("send end");

    #$disconnect->cancel if $disconnect->can('cancel') && !$disconnect->is_ready;

}


async sub  send2 {

    my ($self)=@_;

    #my ($scope, $receive, $send) = @_;
    my $send=$self->{'send'};
    my $receive=$self->{'receive'};
    debug("$self send: $send");


    await $send->({
        type    => 'sse.start',
        status  => 200,
        headers => [ [ 'content-type', 'text/event-stream' ] ],
    });
    
    #my $disconnect = Future->wait_any(watch_sse_disconnect($receive));
    while (1) {

        #last if $disconnect->is_ready;
        await Future::IO->sleep(2);
        await $send->({ type => 'sse.send', data => scalar localtime  });
        #await $send->({ type => 'sse.send', data => Dumper($scope)  });
    }
    #debug("send end");

    #$disconnect->cancel if $disconnect->can('cancel') && !$disconnect->is_ready;

}

async sub send0 {

    my ($self)=@_;

    #my ($scope, $receive, $send) = @_;
    my $send=$self->{'send'};
    my $receive=$self->{'receive'};
    #debug("$self send: $send");


    await $send->({
        type    => 'sse.start',
        status  => 200,
        headers => [ [ 'content-type', 'text/event-stream' ] ],
    });
    
    my $disconnect = Future->wait_any(watch_sse_disconnect($receive));
    while (1) {

        last if $disconnect->is_ready;
        await Future::IO->sleep(2);
        await $send->({ type => 'sse.send', data => scalar localtime  });
        #await $send->({ type => 'sse.send', data => Dumper($scope)  });
    }
    #debug("send end");

    $disconnect->cancel if $disconnect->can('cancel') && !$disconnect->is_ready;

}


#  Doesn't crash, doesn't work, closes connection
sub send4 {


    #  Send SSE response
    #
    my ($self, $event_hr, $cr)=@_;
    debug("$self send: %s", Dumper($event_hr));
    my $send=$self->{'send'};
    
    #await $send->({
    $send->({
        type    => 'sse.start',
        status  => 200,
        headers => [ [ 'content-type', 'text/event-stream' ] ],
    });
    #die "Bang !";

    #  Turn event hash into text/event-stream format
    #
    my @data=map { sprintf('%s: %s', ($_ =>$event_hr->{$_})) } keys %{$event_hr};
    my $data=join("\n", @data, undef);
    debug("sse return: $data");
    
    

    #my $disconnect = Future->wait_any(watch_sse_disconnect($receive));
    #while (1) {

    #last if $disconnect->is_ready;
        #await Future::IO->sleep(2);
        $send->({ type => 'sse.send', data => scalar localtime  });
    #await $send->({ type => 'sse.send', data => Dumper($event_hr)  });
    #$send->({ type => 'sse.send', data => 'Hello'  });
    #}

}

sub DESTROY {

    debug(shift().' destroy');
    
} 
1;

__END__


sub new {


    #  New PSGI request
    #
    my ($class, %r)=@_;
    debug("$class, r: %s, calller:%s", Dumper(\%r, [caller(0)]));
    
    
    #  Try to figure out filename user wants
    #
    unless ($r{'filename'}) {
    
    
        #  Not supplied - need to work out
        #
        debug('filename not supplied, determining from request');

    
        #  Iterate through options. If *not* supplied by SCRIPT_FILENAME keep going.
        #
        my $fn;
        unless (($fn=$ENV{'SCRIPT_FILENAME'}) && !$r{'uri'}) {
        
        
            #  Need to calc from document root in PSGI environment
            #
            debug('not supplied in SCRIPT_FILENAME or r{uri}. calculating');
            if (my $dn=($r{'document_root'} || $ENV{'DOCUMENT_ROOT'} || $Dir_config_env{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT)) {
            
                #  Get from URI and location
                #
                my $uri=$r{'uri'} || $ENV{'PATH_INFO'} || $ENV{'SCRIPT_NAME'};
                debug("uri: $uri");
                $fn=File::Spec->catfile($dn, split m{/+}, $uri); #/
                debug("fn: $fn from dn: $dn, uri: $uri");
                
            }
            
            
            #  IIS/FastCGI, not tested recently unsure if works
            #
            elsif ($fn=$ENV{'PATH_TRANSLATED'}) {

                #  Feel free to let me know a better way under IIS/FastCGI ..
                my $script_fn=(File::Spec::Unix->splitpath($ENV{'SCRIPT_NAME'}))[2];
                $fn=~s/\Q$script_fn\E.*/$script_fn/;
                debug("fn: $fn derived from PATH_TRANSLATED script_fn: $script_fn");
            }
            
            
            #  Need to add default psp file ?
            #
            #unless ($fn=~/\.psp$/) { # fastest
            unless ($fn=~WEBDYNE_PSP_EXT_RE) { # fastest

                #  Is it a directory that exists ? Only append default document if that is the case, else let the api code
                #  handle it
                #
                if  ((-d $fn) || !$fn) {
                    
            
                    #  Append default doc to path, which appears at moment to be a directory ?
                    #
                    my $document_default=$r{'document_default'} || $Dir_config_env{'DOCUMENT_DEFAULT'} || $DOCUMENT_DEFAULT;
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
                    $fn=undef;
                }
            }
        }


        #  Final sanity check
        #
        debug("final fn: $fn");
        $r{'filename'}=$fn; 
        
    }
    
    
    #  Finished, pass back
    #
    return bless \%r, $class;

}


sub new_from_filename {

    #  Test method, not used
    #
    my ($class, $fn, $select_fh)=@_;
    my %r=(filename=>$fn, select=>$select_fh, env=>\%ENV);
    return bless(\%r, $class);
    
}


sub content_type {

    my $r=shift();
    my $hr=$r->headers_out();
    #@_ ? $r->headers_out()->{'Content-Type'}=shift() : $r->SUPER::content_type();
    return @_ ? $r->headers_out()->{'Content-Type'}=shift() : ($r->headers_out()->{'Content-Type'} || $ENV{'CONTENT_TYPE'});

}


sub custom_response {

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


sub location {


    #  Equiv to Apache::RequestUtil->location;
    #
    my $r=shift();
    debug("r: $r, caller: %s", Dumper([caller(0)]));
    my $location;
    my $constant_hr=$WEBDYNE_DIR_CONFIG;
    my $constant_server_hr;
    if (my $server=$Dir_config_env{'WebDyneServer'} || $ENV{'SERVER_NAME'}) {
        $constant_server_hr=$constant_hr->{$server} if exists($constant_hr->{$server})
    }
    if ($Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'}) {

        #  APPL_MD_PATH is IIS virtual dir. If that or a fixed location set use it.
        #
        $location=$Dir_config_env{'WebDyneLocation'} || $ENV{'APPL_MD_PATH'};
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
        $r->status(RC_NOT_FOUND);
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


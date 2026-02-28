
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


package WebDyne::Request::Fake;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized);


#  External modules
#
use Cwd qw(fastcwd);
use Data::Dumper;
use HTTP::Status qw(status_message HTTP_OK HTTP_NOT_FOUND HTTP_FOUND);
use HTTP::Headers::Fast;
use WebDyne::Util;
use WebDyne::Constant;
use URI;


#  Var to hold package wide hash, for data shared across package
#
#my %Package;


#  Snapshot environment for Dir_config
#
#my %Dir_config_env;


#  Version information
#
$VERSION='2.075';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  Do ENV filtering here
#
%ENV=(
    (map { $_=>$ENV{$_}  } (
        grep { defined($ENV{$_}) } qw(
            DOCUMENT_DEFAULT
            DOCUMENT_ROOT
            REQUEST_METHOD
            REQUEST_URI
            PATH_INFO
            SCRIPT_NAME
            QUERY_STRING
            SERVER_PROTOCOL
            SERVER_NAME
            SERVER_PORT
            REMOTE_ADDR
            REMOTE_PORT
            REMOTE_USER
            AUTH_TYPE
            HTTPS 
            APPL_MD_PATH
        ),
        grep {/^WEBDYNE/i} keys %ENV,
        grep {/^HTTP/i} keys %ENV,
        grep {/^CONTENT/i} keys %ENV,
    ))
);


#  Run init code for utility accessors unless already done. Picked method() as arbitrary test
#
&init() unless defined(&method);


#  All done. Positive return
#
1;


#==================================================================================================

sub init0 { # no subsort

    #  Load quick and dirty mod_perl equivalent handler accessors that get info from
    #  environment vars if they exist
    #
    my %handler=(
        #method          => ['REQUEST_METHOD', 'GET'],
        #protocol        => ['SERVER_PROTOCOL', 'HTTP/1.0'],
        args            => ['QUERY_STRING'],
        path_info       => ['PATH_INFO'],
        content_length  => ['CONTENT_LENGTH'],
        hostname        => ['SERVER_NAME'], # Should probably be actual server host name - Fix
        get_server_name => ['SERVER_NAME'],
        get_server_port => ['SERVER_PORT'],
        get_remote_host => ['REMOTE_ADDR'],
        user            => ['REMOTE_USER'],
        ap_auth_type    => ['AUTH_TYPE'],
        unparsed_uri    => ['REQUEST_URI'],
    );
    while (my ($k, $v)=each %handler) {
        *{$k}=sub { return $ENV{$v->[0]} || $v->[1] } unless defined &{$k}
    }

}

use CGI::Cookie;

sub init {

    #  Setup pass through methods
    #
    require WebDyne::Request::Common;
    my %method=(
        req => {
            accept_encoding     => sub { shift()->headers_in('Acccept-Encoding') },
            accept_language     => sub { shift()->headers_in('Acccept-Language') },
            accept              => sub { shift()->headers_in('Accept') },
            authority           => sub { shift()->uri->authority },
            args                => sub { shift()->env->{'QUERY_STRING'} },
            as_string           => undef,
            authorizarion       => sub { shift()->headers_in('Authorization') },
            auth_type           => sub { shift()->{'env'}->{'AUTH_TYPE'} },
            base_url            => sub { URI->new($_[0]->host . $_[0]->script_name()) },
            base                => 'base_url',
            body                => sub { my $r=shift(); $r->{'body'} ? $r->{'body'} : do { if(my $fh=$r->{'input'}) { local $/; <$fh> } } },
            body_handle         => sub { shift->{'input'} },
            cache_control       => sub { shift()->headers_in('Cache-Control') },
            charset             => sub { ()=(shift()->content_type=~/charset=(.*?)/)[0] },
            client_address      => sub { shift()->env->{'REMOTE_ADDR'} },
            content_encoding    => sub { shift()->headers_in('Content-Encoding') },
            #content_length      => sub { shift()->headers_in('Content-Length') },
            content_length      => undef,
            #content_type        => sub { shift()->headers_in('Content-Type') },
            content_type        => undef,
            content             => 'body',
            cookies             => undef,
            cookie              => sub { shift()->cookies(@_) },
            custom_response     => undef,
            cwd                 => undef,
            dir_config          => undef,
            document_root       => undef,
            env                 => sub { \%ENV },
            etag                => sub { shift()->headers_in('If-None-Match') },
            filename            => undef,
            finalize            => undef,
            finfo               => undef,
            form_parameters     => undef,
            forwarded_for       => sub { shift()->headers_in('X-Forwarded-For') },
            fragment            => sub { shift()->uri->fragment },
            handler             => undef,
            headers_in          => undef,
            headers_out         => undef,
            header_only         => undef,
            host                => sub { shift()->uri->host if $_[0]->uri->authority },
            hostname            => sub { shift()->env->{'SERVER_NAME'} }, # Prob should be local host name
            http_version        => 'protocol',
            https               => sub { shift()->env->{'HTTPS'} },
            #id                  => sub { shift()->env->{'psgi.request_id'} },
            id                  => undef,
            if_modified_since   => sub { shift()->headers_in('If-Modified-Since') },
            if_none_match       => sub { shift()->headers_in('If-None_Match') },
            is_ajax             => sub { (shift()->headers_in('X-Requested-With') eq 'XMLHttpRequest') },
            input               => sub { shift()->{'input'} },
            is_main             => undef,
            location            => undef,
            log_error           => undef,
            lookup_file         => undef,
            lookup_uri          => undef,
            main                => undef,
            media_type          => sub { ()=(shift()->content_type=~/(.*?);/) },
            method              => sub { shift->env->{'REQUEST_METHOD'} },
            mtime               => undef,
            multipart_parameters=> undef,
            next                => undef,
            notes               => undef,
            origin              => sub { shift()->headers_in('Origin') },
            output_filters      => undef,
            path_parameters     => undef,
            path                => 'path_info',
            path_info           => sub { shift->env->{'PATH_INFO'} },
            #parsed_uri          => 'uri',
            #parsed_uri          => undef,
            #port                => sub { shift()->env->{'SERVER_PORT'} },
            pool                => undef,
            preferred_language  => undef,
            preferred_media_type=> undef,
            prev                => undef,
            print               => undef,
            #protocol            => 'protocol',
            protocol            => sub { shift()->env->{'SERVER_PROTOCOL'} },
            query_parameters    => undef,
            query_string        => 'args',
            referer             => sub { shift()->headers_in('Referer') },
            redirect            => undef,
            remote_address      => 'client_address',
            remote_host         => 'client_address',
            remote_port         => sub { shift()->env->{'REMOTE_PORT'} },
            remote_user         => 'user',
            request_time        => undef,
            register_cleanup    => undef,
            route               => undef,
            run                 => undef,
            scheme              => undef,
            script_name         => sub { shift()->env->{'SCRIPT_NAME'} },
            secure              => sub { (shift()->https eq 'on') },
            server_name         => sub { shift()->env->{'SERVER_NAME'} },
            server_port         => sub { shift()->env->{'SERVER_PORT'} },
            sendfile            => undef,
            session_id          => undef,
            session             => undef,
            stat                => undef,
            status              => undef,
            status_line         => undef,
            uploads             => undef,
            uri                 => sub { URI->new(shift()->filename()) },
            #uri                 => undef,
            unparsed_uri        => sub { shift()->filename() },
            url                 => 'uri',
            user_agent          => sub { shift()->headers_in('User-Agent') },
            user                => sub { shift()->env->{'REMOTE_USER'} },
            write               => undef,
        },
        res => {(
           #status headers body header content_typee content_length content_encoding redirect location cookies finalize to_app
        )},
            
    );
    my %method_all;
    foreach my $handler (qw(req res)) {
        while (my ($method, $dispatch)=each %{$method{$handler}}) {
            $method_all{$method}++;
            if (defined(*{sprintf('%s::%s', __PACKAGE__, $method)}{'CODE'})) {
                #  Do nothing, defined here
                #
                die("duplicate method for $method") if $dispatch;
                debug("skip $method, defined in this package");
                
            }
            elsif (!defined($dispatch)) {
                #  Do nothing, will fall through to Fake
                #
                debug("skip $method, will inherit from Fake");
                next;
            }
            elsif (ref($dispatch) eq 'CODE') {
                #  Turn into method
                #
                debug("setting method: $method to code ref: $dispatch");
                *{$method}=$dispatch;
            }
            else {
                #  Existing method
                #
                debug("setting method: $method to $handler: $dispatch");
                *{$method}=sub { shift()->$dispatch };
            }
        }
    }
    
    #  Make sure we don't have more methods defined here than we need
    #
    my @method_package=grep { $_ eq lc($_) } grep { defined *{sprintf('%s::%s', __PACKAGE__, $_)}{'CODE'} } keys %{sprintf('%s::', __PACKAGE__)};
    my %method_package=map { $_=>1 } @method_package;
    map { delete $method_package{$_} } keys %method_all;
    my @method_orphan;
    use B ();
    foreach my $method (keys %method_package) {
        if (my $cr=*{sprintf('%s::%s', __PACKAGE__, $method)}{'CODE'}) {
            if (my $gv=B::svref_2object($cr)->GV) {
                if ($gv->STASH->NAME eq __PACKAGE__) {
                    push @method_orphan, $method;
                }
            }
        }
    }
    #die Dumper(\@method_orphan) if @method_orphan;
        
    #  Check we haven't missed any methods
    #
    foreach my $method (sort @{&WebDyne::Request::Common::methods}) {
        unless ($method_all{$method}) {
            warn "missing method definition: $method";
            sleep 1;
        }
        unless (__PACKAGE__->can($method)) {
            warn "missing method function: $method";
            sleep 1;
        }
    }
    
}


sub cookies {

    my $r=shift();
    my %cookies=CGI::Cookie->parse(
        $r->headers_in->{'Cookie'});
    if (@_) {
        %cookies=(%cookies, @_);
        $r->headers_out('Cookie', CGI::Cookie->new(%cookies)->as_string());
    }
    return \%cookies;
}


sub dir_config {

    
    #  Newer more comprehensive dir_config that pulls from WEBDYNE_CONF
    #
    my ($r, $key)=@_;
    debug("r: $r, caller: %s", Dumper([caller(0)]));
    

    #  Get hash ref from config file
    #
    my $constant_hr=$WEBDYNE_DIR_CONFIG;
    debug('using constant_hr: %s', Dumper($constant_hr));


    #  Optionally load WEBDYNE_DIR_CONFIG from current dir
    #
    if ($WEBDYNE_DIR_CONFIG_CWD_LOAD) {
    

        #  Yes, wanted. Get cwd, skip if already processed
        #
        my $cwd_dn=$r->cwd();
        my $dir_config_hr=($_{'_dir_config'}{$cwd_dn} ||= do {
            my $webdyne_conf_fn=File::Spec->catfile($cwd_dn, sprintf('.%s', $WEBDYNE_CONF_FN));
            debug("fn: $webdyne_conf_fn");
            if (-f $webdyne_conf_fn) {
                debug("found: $webdyne_conf_fn, reading");
                my $webdyne_conf_hr=do($webdyne_conf_fn) ||
                    warn "unable to read document root dir_config constant file, $!";
                debug('webdyne_conf_hr: %s', Dumper($webdyne_conf_hr));
                $webdyne_conf_hr->{'WebDyne::Constant'}{'WEBDYNE_DIR_CONFIG'};
            }} || {}
        );
        if (keys %{$dir_config_hr}) {
            $constant_hr={
                %{$constant_hr},
                %{$dir_config_hr}
            } 
        }
    }    


    #  OK - heirarchy is this:
    #
    #  If WEBDYNE_PSGI_DIR_CONFIG=$hr order of return
    #
    #  $ENV{$key} # Wins everything
    #  $hr->{$servername}{$location}{$key}
    #  $hr->{$servername}{''}{$key}
    #  $hr->{$servername}{$key}
    #  $hr->{$location}{$key}
    #  $hr->{''}{$key} 
    #  $hr->{$key}
    #

    if ($key) {
    
        #  Key specified, returning just that value
        #
        #if (exists $Dir_config_env{$key}) {
        if (exists $ENV{$key}) {
        
            #  $ENV{$key} # Wins everything
            #
            #debug('found $ENV{%s}, returning %s', $key, $Dir_config_env{$key});
            debug('found $ENV{%s}, returning %s', $key, $ENV{$key});
            #return $Dir_config_env{$key};
            return $ENV{$key};
            
        }
        else {
            

            #  Get location we are operating in
            #
            my $location=$r->location();
            debug("in dir_config looking for key: $key at location: $location");
            
            
            #  Array of hashes we may need to look through
            #
            my @constant_hr=($constant_hr);


            #  Do we have $hr->{$servername}{$location} ?
            #
            if (my $server=($ENV{'WebDyneServer'} || $ENV{'HOSTNAME'} ||  $ENV{'SERVER_NAME'})) {

                #  Have $servername
                #
                debug("using server: $server");
                if (exists $constant_hr->{$server}) {
                
                    #  Add to array of hashes we have to look at
                    #
                    unshift @constant_hr, (my $constant_server_hr=$constant_hr->{$server});
                    debug("pushing $constant_server_hr onto dir_config review stack: %s", Dumper($constant_server_hr));
                    
                }
                
            }
            
            
            #  Now iterate across array, return on first match
            #
            foreach my $hr (@constant_hr) {
                my %location;
                foreach my $hr_key ($location, '') {
                    next if ($location{$location}++);
                    debug("looking at hr: $hr, hr_key: $hr_key");
                    #  Maybe $hr->{$location}{$key} or $hr->{''}{$key} ?
                    #
                    if (exists $constant_hr->{$hr_key}) {
                        debug("found hr: $hr, hr_key: $hr_key");
                        return $hr->{$hr_key}{$key} if exists($hr->{$hr_key}{$key});
                    }
                    else {
                        debug("no match on hr: $hr, hr_key: $hr_key");
                    }
                }
                #  No - $hr->{$key} is last chance
                #
                if (exists $hr->{$key}) {
                    debug("found hr: $hr, key: $key");
                    return $hr->{$key}
                }
                else {
                    debug("no match on hr: $hr, key: $key");
                }
            }
                
            #  Nothing found
            #
            debug("no key found for location: $location or any other match");
            return undef;
            
        }
                
    }
    else {

        #  Return dump of whole thing with ENV vars taking precendence at top level. Scrub mixing in ENV at moment, exposes
        #  too many non WebDyne vars if called with dir_config(). Do properly with Plack::Middleware::AddEnv or similar later
        #
        #my %dir_config=(%{$constant_hr}, %Dir_config_env);
        my %dir_config=(
            %{$constant_hr}, 
            (map { $_=>$ENV{$_} } grep {/^WebDyne/i} keys %ENV), 
            (map { $_=>$ENV{$_} } grep {exists $ENV{$_} } keys %{$constant_hr})
            #(map { $_=>$ENV{$_} } @{$WEBDYNE_PSGI_ENV_KEEP},
            #%{$WEBDYNE_PSGI_ENV_SET}
        );
        return \%dir_config;
    }

}


sub filename {

    my $r=shift();

    #  Store cwd as takes a fair bit of processing time.
    File::Spec->rel2abs($r->{'filename'}, ($_{'_cwd'} ||= fastcwd()));

}


sub headers_in {
    my $r=shift();
    if (@_) {
        return ($r->{'headers_in'} ||= HTTP::Headers::Fast->new())->header(@_);
    }
    else {
        return ($r->{'headers_in'} ||= HTTP::Headers::Fast->new());
    }
}


sub headers_out {
    my $r=shift();
    if (@_) {
        return ($r->{'headers_out'} ||= HTTP::Headers::Fast->new())->header(@_);
    }
    else {
        return ($r->{'headers_out'} ||= HTTP::Headers::Fast->new());
    }
}


sub is_main {

    my $r=shift();
    $r->{'main'} ? 0 : 1;

}


sub log_error {

    my $r=shift();
    warn(@_) unless !$r->{'warn'};

}



sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child;
    if ($fn!~WEBDYNE_PSP_EXT_RE) { # fastest


        #  Static file. Should migrate to this module but OK is PSGI for moment
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
    my $fn=File::Spec::Unix->catfile((File::Spec->splitpath($r->filename()))[1], $uri);
    return $r->lookup_file($fn);

}


sub main {

    my $r=shift();
    #@_ ? $r->{'main'}=shift() : $r->{'main'} || $r;
    @_ ? $r->{'main'}=shift() : $r->{'main'};

}


sub new {

    my ($class, %r)=@_;
    debug("$class, r:%s", Dumper(\%r));
    my $r=bless(\%r, $class);
    foreach my $env ((grep {/^HTTP_/} keys %ENV), qw(CONTENT_TYPE CONTENT_LENGTH)) {
        my $header=$env;
        exists $ENV{$header} || next;
        my $value=$ENV{$header};
        $header=~s/^HTTP_//;
        $header=~s/_/-/g;
        debug("setting header: $header, value: $value");
        $r->headers_in($header, $value);
    }
        
    #$r->headers_in(
    #    'Content-Type'      => $ENV{'CONTENT_TYPE'},
    #    'Content-Length'    => $ENV{'CONTENT_LENGTH'},
    #    'Host'              => $ENV{'HTTP_HOST'},
    #    'User-Agent'        => $ENV{'HTTP_USER_AGENT'},
    #    'Accept'            => $ENV{'HTTP_ACCEPT'},
    #    'Accept-Encoding'   => $ENV{'HTTP_ACCEPT_ENCODING'},
    #    'Cookie'            => $ENV{'HTTP_COOKIE'},
    #    'Referer'           => $ENV{'HTTP_REFERER'},
    #    'Authorization'     => $ENV{'HTTP_AUTHORIZATION'},
    #);    
    return $r;
    #return bless \%r, $class;

}


sub notes {

    my ($r, $k, $v)=@_;
    if (@_ == 3) {
        return $r->{'_notes'}{$k}=$v
    }
    elsif (@_ == 2) {
        return $r->{'_notes'}{$k}
    }
    elsif (@_ == 1) {
        return ($r->{'_notes'} ||= {});
    }
    else {
        return err('incorrect usage of %s notes object, r->notes(%s)', +__PACKAGE__, join(',', @_[1..$#_]));
    }

}


sub parsed_uri0 {

    my $r=shift();
    require URI;
    URI->new($r->uri());

}


sub prev {

    my $r=shift();
    @_ ? $r->{'prev'}=shift() : $r->{'prev'};

}


sub print {

    my $r=shift();
    my $fh=$r->{'select'} || \*STDOUT;
    debug("print fh: $fh");
    CORE::print $fh ((ref($_[0]) eq 'SCALAR') ? ${$_[0]} : @_);

}


sub register_cleanup {

    #my $r=shift();
    my ($r, $cr)=@_;
    push @{$r->{'register_cleanup'} ||= []}, $cr;

    #my $ar=$r->{'register_cleanup'} ||= [];
    #push @

}


sub cleanup_register {

    &register_cleanup(@_);

}


sub pool {

    #  Used by mod_perl2, usually for cleanup_register in the form of $r->pool->cleanup_register(), so just
    #  return $r and let the code then call cleanup_register
    #
    my $r=shift();

}


sub run {

    my ($r, $self)=@_;
    debug("r: $r, self: $self");
    (ref($self) || $self)->handler($r);
    #(ref($self) ? $self : $self)->handler($r);

}


sub status {

    my $r=shift();
    @_ ? $r->{'status'}=shift() : $r->{'status'} || HTTP_OK;

}


sub uri0 {


    #  Probably should subtract root_dn/DOCUMENT_ROOT
    shift()->{'filename'}

}


sub document_root {

    my $r=shift();
    @_ ? $r->{'document_root'}=shift() : $r->{'document_root'} || ($ENV{'DOCUMENT_ROOT'} || fastcwd());
    
}


sub output_filters {

    #  Stub
}




sub location {


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



sub header_only {

    #  Stub
}


sub set_handlers {

    #  Stub
}


sub noheader {

    my $r=shift();
    @_ ? $r->{'header'}=shift() : $r->{'header'};

}


sub send_http_header {

    my $r=shift();
    return unless $r->{'header'};
    my $fh=$r->{'select'} || \*STDOUT;
    CORE::printf $fh ("Status: %s\n", $r->status());
    #while (my ($header, $value)=each(%{$r->{'headers_out'}})) {
    while (my ($header, $value)=each(%{$r->headers_out()})) {
        CORE::print $fh ("$header: $value\n");
    }
    CORE::print $fh "\n";

}


sub content_type {

    my ($r, $content_type)=@_;
    #return ($content_type ? $r->{'headers_out'}{'Content-Type'}=$content_type : $ENV{'CONTENT_TYPE'});
    #return ($content_type ? $r->headers_out('Content-Type', $content_type) : $ENV{'CONTENT_TYPE'});
    return ($content_type ? $r->headers_out('Content-Type', $content_type) : $r->headers_in('Content-Type'));
    #CORE::print("Content-Type: $content_type\n");

}


sub content_length {

    my ($r, $content_length)=@_;
    #return ($content_type ? $r->{'headers_out'}{'Content-Type'}=$content_type : $ENV{'CONTENT_TYPE'});
    return ($content_length ? $r->headers_out('Content-Length', $content_length) : $r->headers_in('Content-Length'));
    #CORE::print("Content-Type: $content_type\n");

}


sub handler {

    # Replicate mod_perl handler function
    #
    my ($r, $handler)=@_;
    return ($handler ? $r->{'handler'}=$handler : $r->{'handler'} ||= 'default-handler');

}


sub custom_response {

    my ($r, $status)=(shift(), shift());
    while ($r->prev) {$r=$r->prev}
    debug("in custom response, status $status");
    @_ ? $r->{'custom_response'}{$status}=shift() : $r->{'custom_response'}{$status};

}





sub cwd {

    #  Return cwd of current psp file
    #
    my $r=shift();
    return $r->{'_cwd'} ||= do {
        debug("$r, fn: %s", $r->filename());
        my $fn=$r->filename();
        my $dn;
        unless (-d ($dn=File::Spec->rel2abs($fn))) {
            #  Not a directory, must be file
            #
            $dn=(File::Spec->splitpath($fn))[1] || fastcwd();
            debug("return calculated dn: $dn");
            $dn;
        }
        else {
            debug("return existing dn: $dn");
            $dn;
        }
        
    }

}


# TO DO
#
sub status_line {

    my $r=shift();
    return sprintf('%s %s',$r->status, status_message($r->status));
    #@_ ? $r->{'header'}=shift() : $r->{'header'};
    
}


sub content_encoding0 {

}



sub write {

    #  Just print for Fake, other handlers can map to native
    #
    return &print(@_);
    
}


sub finalize {

    #  No op
    
}


sub redirect {

    #  No op
    

}


sub env0 {

    return \%ENV;

}


sub subprocess_env {

    return &env(@_)
    
}

sub as_string {

}

sub set_etag0 {

}

sub mtime {

}

sub next {

}

sub preferred_language {

}


sub preferred_media_type {

}


sub session {

}

sub session_id {

}

sub route {

}

sub path_parameters {

}


sub sendfile {

}


sub finfo {

    use File::stat;
    return stat(shift->filename());
    
}

sub form_parameters {

}

sub id {

}

sub multipart_parameters {

}

sub query_parameters {

}

sub request_time {

}

sub scheme {

    'http',
    
}

sub script_name0 {

}

sub uploads {

}


# Error handling, autoload


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


sub AUTOLOAD { #no subsort

    my ($r, $v)=@_;
    debug("$r AUTOLOAD: $AUTOLOAD, v: $v");
    my $k=($AUTOLOAD=~/([^:]+)$/) && $1;
    warn(sprintf("Unhandled '%s' method, using AUTOLOAD. Caller:%s", $k, Dumper([caller(0)])));
    $v ? $r->{$k}=$v : $r->{$k};


}


sub DESTROY { #no subsort

    my $r=shift();
    debug("$r DESTROY");
    if (my $cr_ar=delete $r->{'register_cleanup'}) {
        foreach my $cr (@{$cr_ar}) {
            $cr->($r);
        }
    }

}

__END__

sub method0 {

    return $ENV{'REQUEST_METHOD'} || 'GET';
    
}


sub protocol0 {

    return $ENV{'SERVER_PROTOCOL'} || 'HTTP/1.0';
    
}


sub dir_config0 {

    #  Old very simplistic dir_config
    #
    my ($r, $key)=@_;
    return $ENV{$key};

}

sub headers0 {

    #  Set/get header. r=request, d=direction(in/out), k=key, v=value
    #
    my ($r, $d, $h, $v, %param)=@_;
    
    if (@_ >= 4) {
        #return $r->{$d}{$h}=$v;
        $r->{$d}{$h}=$v;
        while (my($key,$val)=each %param) {
            $r->{$d}{$key}=$val;
        }
        #die Dumper($r->{$d});
        return $v;
    }
    elsif (@_ == 3) {
        return $r->{$d}{$h}
    }
    elsif (@_ == 2) {
        return ($r->{$d} ||= {});
    }
    else {
        return err("incorrect usage of $r object, direction:%s, header: %s, value: %s", $d, $h, $v);
    }

}


sub headers_out0 {

    my $r=shift();
    return $r->headers('headers_out', @_);
    
}


sub headers_in0 {

    my $r=shift();
    return $r->headers('headers_in', @_);
    
}

sub lookup_file0 {

    #  Old, simplistic version
    #
    my ($r, $fn)=@_;
    my $r_child=ref($r)->new(filename => $fn, main=>$r) || return err();

}

sub location0 {

    #  Get/set location
    my ($self, $location)=@_;
    if ($location) {
        return $self->{'location'}=$location;
    }
    else {
        return $self->{'location'} || $ENV{'WebDyneLocation'}
    }

}

sub custom_response0 {

    my ($r, $status, @param)=@_;
    debug("r: $r, status: $status, %s", \@param);
    $r->status($status);
    $r->send_http_header();
    $r->print(@param);

}


sub args0 {

    return $ENV{'QUERY_STRING'};
    
}

sub scheme0 {

    #  Always http for Fake requests, other handlers return appropriate
    #
    return 'http';
    
}

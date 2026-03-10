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

package WebDyne::Request::Apache;


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
use HTTP::Headers::Fast;


#  mod_perl 2 modules
#
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Connection ();
use Apache2::Const ();
use Apache2::ServerUtil ();
use APR::Table ();


#  WebDyne modules
#
use WebDyne::Util;
use WebDyne::Constant;
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
            args                => 'args',
            as_string           => undef,
            authority           => undef,
            authorization       => undef,
            auth_type           => undef,
            base                => undef,
            base_url            => undef,
            body_handle         => undef,
            body                => undef,
            cache_control       => undef,
            charset             => undef,
            cleanup_register    => undef,
            client_address      => sub { &remote_address(@_) },
            #content             => 'body',
            content             => sub { &body(@_) },
            content_encoding    => undef,
            content_length      => undef,
            content_type        => undef,
            cookies             => undef,
            cookie              => undef,
            custom_response     => undef,
            cwd                 => undef,
            dir_config          => undef,
            document_root       => 'document_root',
            env                 => undef,
            etag                => undef,
            filename            => 'filename',
            finalize            => undef,
            finfo               => undef,
            form_parameters     => undef,
            forwarded_for       => undef,
            fragment            => undef,
            handler             => 'handler',
            header              => 'headers_in',
            headers             => 'headers_in',
            header_only         => 'header_only',
            headers_in          => undef,
            headers_out         => undef,
            hostname            => 'hostname',
            host                => undef,
            https               => undef,
            http_version        => 'protocol',
            id                  => undef,
            if_modified_since   => undef,
            if_none_match       => undef,
            input               => sub { &body_handle(@_) },
            is_ajax             => undef,
            is_main             => undef,
            location            => undef,
            log_error           => undef,
            lookup_file         => 'lookup_file',
            lookup_uri          => 'lookup_uri',
            main                => undef,
            media_type          => undef,
            method              => 'method',
            mtime               => undef,
            multipart_parameters=> undef,
            next                => undef,
            notes               => 'notes',
            origin              => undef,
            output_filters      => undef,
            path_info           => sub { shift()->uri->path },
            path_parameters     => undef,
            path                => sub { &path_info(@_) },
            pool                => 'pool',
            preferred_charset   => undef,
            preferred_encoding  => undef,
            preferred_language  => undef,
            preferred_media_type=> undef,
            prev                => undef,
            print               => 'print',
            protocol            => 'protocol',
            query_parameters    => undef,
            query_string        => 'args',
            redirect            => undef,
            referer             => undef,
            register_cleanup    => undef,
            remote_address      => undef,
            remote_host         => undef,
            remote_port         => undef,
            remote_user         => 'user',
            request_time        => undef,
            route               => undef,
            run                 => undef,
            scheme              => undef,
            script_name         => undef,
            secure              => undef,
            sendfile            => undef,
            send_http_header    => undef,
            server_name         => undef,
            server_port         => undef,
            session_id          => undef,
            session             => undef,
            set_handlers        => 'set_handlers',
            status_line         => 'status_line',
            status              => 'status',
            unparsed_uri        => 'unparsed_uri',
            uploads             => undef,
            uri                 => undef,
            url                 => undef,
            user_agent          => undef,
            user                => 'user',
            write               => undef,
        },
        res => {(
           #status headers body header content_type content_length content_encoding redirect location cookies finalize to_app
        )},
            
    );
    my %method_check;
    foreach my $handler (qw(req res)) {
        while (my ($method, $dispatch)=each %{$method{$handler}}) {
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
                #  Apache method
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


    #  New Apache request
    #
    my ($class, $r, %opt)=@_;
    debug("$class, r: %s, opt:%s, calller:%s", Dumper($r, \%opt, [caller(0)]));


    #  Require Apache request record
    #
    $r || return err('no Apache request supplied');


    #  Finished, pass back
    #
    return bless { req => $r, %opt }, $class;

}


sub req {
    return shift()->{'req'};
}


sub _headers {

    my ($r, $direction, @param)=@_;
    my $table=$r->{'req'}->$direction;
    if (@param == 1) {
        return  $table->get($param[0]);
    }
    elsif (@param > 1) {
         while (my ($k, $v) = splice(@param, 0, 2)) {
            $table->set($k => $v);
        }
        return $r;
    }
    else {
        my $headers_or=HTTP::Headers::Fast->new();
        $table->do(sub { $headers_or->header($_[0] => $_[1]); return 1; });
        return $headers_or;
    }
}
 
sub headers_in {
    shift()->_headers('headers_in', @_);
}   


sub headers_out {
    shift()->_headers('headers_out', @_);
}   



sub content_type {
    my $r=shift();
    return @_ ? $r->{'req'}->content_type(@_) : $r->{'req'}->content_type();
}


sub content_length {
    my $r=shift();
    return @_ ? $r->headers_out('Content-Length', shift()) : $r->headers_in('Content-Length');
}


sub content_encoding {
    my $r=shift();
    return @_ ? $r->headers_out('Content-Encoding', shift()) : $r->headers_in('Content-Encoding');
}


sub host {
    my $r=shift();
    return $r->headers_in('Host');
}


sub server_name {
    my $r=shift();
    return $r->{'req'}->can('get_server_name') ? $r->{'req'}->get_server_name() : $r->{'req'}->hostname();
}


sub server_port {
    my $r=shift();
    if ($r->{'req'}->can('get_server_port')) {
        return $r->{'req'}->get_server_port();
    }
    if (my $conn=$r->{'req'}->connection()) {
        return $conn->local_addr->port if $conn->can('local_addr');
    }
    return undef;
}


sub remote_address {
    my $r=shift();
    my $req=$r->{'req'};
    if (my $conn=$req->connection()) {
        return $conn->client_ip if $conn->can('client_ip');
        return $conn->remote_ip if $conn->can('remote_ip');
        if ($conn->can('remote_addr')) {
            my $addr=$conn->remote_addr;
            return $addr->ip_get if ($addr && $addr->can('ip_get'));
        }
    }
    return $req->subprocess_env('REMOTE_ADDR') if $req->can('subprocess_env');
    return undef;
}


sub remote_host {
    my $r=shift();
    my $req=$r->{'req'};
    if ($req->can('get_remote_host')) {
        return $req->get_remote_host(Apache2::Const::REMOTE_NAME());
    }
    return $r->remote_address();
}


sub remote_port {
    my $r=shift();
    my $req=$r->{'req'};
    if (my $conn=$req->connection()) {
        return $conn->client_port if $conn->can('client_port');
        if ($conn->can('client_addr')) {
            my $addr=$conn->client_addr;
            return $addr->port if ($addr && $addr->can('port'));
        }
        return $conn->remote_port if $conn->can('remote_port');
        if ($conn->can('remote_addr')) {
            my $addr=$conn->remote_addr;
            return $addr->port if ($addr && $addr->can('port'));
        }
    }
    return $req->subprocess_env('REMOTE_PORT') if $req->can('subprocess_env');
    return undef;
}


sub auth_type {
    my $r=shift();
    return $r->{'req'}->can('ap_auth_type') ? $r->{'req'}->ap_auth_type() : $r->{'req'}->auth_type();
}


sub https {
    my $r=shift();
    return (($r->headers_in('HTTPS') || $r->{'req'}->subprocess_env('HTTPS') || '') eq 'on');
}


sub secure {
    return shift()->https();
}


sub scheme {
    my $r=shift();
    return $r->{'req'}->subprocess_env('REQUEST_SCHEME') ||
        ($r->https() ? 'https' : 'http');
}


sub id {
    return shift()->{'req'}->subprocess_env('UNIQUE_ID')
}


sub env {
    my $r=shift();
    my $table=$r->{'req'}->subprocess_env();
    my %env;
    $table->do(sub { $env{$_[0]}=$_[1]; return 1; });
    return \%env;
}


sub subprocess_env {

    return &env(@_);
    
}


#sub input {
#    #return shift()->{'req'};
#    
#}


sub body {
    my $r=shift();
    return $r->{'body'} if exists $r->{'body'};
    my $len=$r->content_length() || 0;
    return $r->{'body'}='' unless $len;
    my $buf='';
    my $read=0;
    while ($read < $len) {
        my $chunk='';
        my $n=$r->{'req'}->read($chunk, $len-$read);
        last unless $n;
        $read += $n;
        $buf.=$chunk;
    }
    return $r->{'body'}=$buf;
}


sub body_handle {

    my $r=shift();
    unless ($r->{'input'}) {
        no warnings qw(once);
        $r->{'input'}=tie *BODY, WebDyne::Request::Apache::Body_Handle, $r->{'req'};
    }
    return $r->{'input'};
}


sub header_only {
    my $r=shift();
    return $r->{'req'}->header_only() ? 1 : 0;
}


sub request_time {
    my $r=shift();
    return $r->{'req'}->request_time() if $r->{'req'}->can('request_time');
    return time();
}

sub uri {
    #return URI->new(shift()->{'req'}->uri);
    my $r=shift();
    my $uri_or=URI->new();
    $uri_or->scheme($r->scheme);
    $uri_or->host($r->server_name);
    $uri_or->port($r->server_port);
    $uri_or->path($r->{'req'}->uri);
    $uri_or->query($r->{'req'}->args);
    return $uri_or->canonical;
}


sub DESTROY {

    my $r=shift();
    untie $r->{'input'} if $r->{'input'};
    
}

package WebDyne::Request::Apache::Body_Handle;

sub TIEHANDLE {
    my ($class, $req) = @_;
    bless { req => $req }, $class;
}

sub READ {
    my ($self, undef, $len, $offset) = @_;
    my $buf;
    my $n = $self->{'req'}->read($buf, $len);
    $_[1] = $buf;
    return $n;
}

sub READLINE {
    my ($self) = @_;
    return $self->{'req'}->readline;
}

1;

__END__

sub _headers_in0 {
    my $r=shift();
    my $table=$r->{'req'}->headers_in();
    if (@_ == 1) {
        return  $table->get($_[0]);
    }
    elsif (@_>1) {
         while (my ($k, $v) = splice(@_, 0, 2)) {
            $table->set($k => $v);
        }
        return $r;
    }
    else {
        my $headers_or=HTTP::Headers::Fast->new();
        $table->do(sub { $headers_or->header($_[0] => $_[1]); return 1; });
        return $headers_or;
    }
}


sub _headers_out0 {
    my $r=shift();
    my $table=$r->{'req'}->headers_out();
    if (@_ == 1) {
        return  $table->get($_[0]);
    }
    elsif (@_>1) {
         while (my ($k, $v) = splice(@_, 0, 2)) {
            $table->set($k => $v);
        }
        return $r;
    }
    else {
        my $headers_or=HTTP::Headers::Fast->new();
        $table->do(sub { $headers_or->header($_[0] => $_[1]); return 1; });
        return $headers_or;
    }
}


sub _headers_out0 {
    my $r=shift();
    my $table=$r->{'req'}->headers_out();
    if (@_) {
        my ($k, $v)=@_;
        return defined($v) ? $table->set($k => $v) : $table->get($k);
    }
    my $headers_or=HTTP::Headers::Fast->new();
    $table->do(sub { $headers_or->header($_[0] => $_[1]); return 1; });
    return $headers_or;
}

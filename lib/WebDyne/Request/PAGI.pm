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
use File::Spec;
use File::Spec::Unix;
use HTTP::Status qw(status_message HTTP_OK HTTP_NOT_FOUND HTTP_FOUND);
use URI;
use Data::Dumper;
use HTTP::Headers::Fast;
use PAGI::Request;


#  WebDyne modules
#
use WebDyne::Util;
use WebDyne::Constant;
use WebDyne::PAGI::Constant;
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
            accept              => undef,
            accept_encoding     => undef,
            accept_language     => undef,
            args                => undef,
            as_string           => undef,
            authority           => undef,
            authorization       => undef,
            auth_type           => undef,
            base                => 'base_url',
            base_url            => 'base_url',
            body_handle         => 'input',
            body                => sub { shift()->body() },
            cache_control       => undef,
            charset             => undef,
            cleanup_register    => undef,
            client_address      => 'client_address',
            content             => 'body',
            content_encoding    => undef,
            content_length      => 'content_length',
            content_type        => 'content_type',
            cookies             => 'cookies',
            cookie              => sub { shift()->cookies(@_) },
            custom_response     => undef,
            cwd                 => undef,
            dir_config          => undef,
            document_root       => undef,
            env                 => 'env',
            etag                => undef,
            filename            => undef,
            finalize            => undef,
            finfo               => undef,
            form_parameters     => 'form_parameters',
            forwarded_for       => undef,
            fragment            => undef,
            handler             => undef,
            header              => 'headers_in',
            header_only         => undef,
            headers_in          => undef,
            headers_out         => undef,
            hostname            => 'hostname',
            host                => 'host',
            https               => 'https',
            http_version        => 'http_version',
            id                  => 'id',
            if_modified_since   => undef,
            if_none_match       => undef,
            input               => 'input',
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
            multipart_parameters=> 'multipart_parameters',
            next                => undef,
            notes               => undef,
            origin              => undef,
            output_filters      => undef,
            path_info           => 'path_info',
            path_parameters     => undef,
            path                => 'path',
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
            redirect            => 'redirect',
            referer             => undef,
            register_cleanup    => undef,
            remote_address      => 'remote_address',
            remote_host         => 'remote_host',
            remote_port         => undef,
            remote_user         => undef,
            request_time        => 'request_time',
            route               => undef,
            run                 => undef,
            scheme              => 'scheme',
            script_name         => undef,
            secure              => 'secure',
            sendfile            => undef,
            send_http_header    => undef,
            server_name         => 'server_name',
            server_port         => 'server_port',
            session_id          => undef,
            session             => undef,
            set_handlers        => undef,
            status_line         => undef,
            status              => 'status',
            unparsed_uri        => 'uri',
            uploads             => 'uploads',
            uri                 => 'uri',
            url                 => 'uri',
            user_agent          => undef,
            user                => undef,
            write               => undef,
        },
        res => {(
           #status headers body header content_type content_length content_encoding redirect location cookies finalize to_app
        )},
        sse => {},
        ws  => {}
            
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
                #  PAGI method
                #
                debug("setting method: $method to $handler: $dispatch");
                *{$method}=sub { shift()->{$handler}->$dispatch(@_) };
            }
        }
    }


    #  Done, do runtime check and return, will warn if we have missed anything
    #
    return handler_methods_check(__PACKAGE__, \%method_check);
    
}


sub req {
    return shift()->{'req'};
}

sub res {
    return shift()->{'res'};
}

sub sse {
    return shift()->{'sse'};
}

sub ws {
    return shift()->{'ws'};
}


sub env {
    return shift()->{'scope'};
}


sub id {
    return shift()->{'scope'}{'request_id'};
}


sub scheme {
    return shift()->req->scheme();
}


sub https {
    return (shift()->scheme() || '') eq 'https';
}


sub secure {
    return (shift()->scheme() || '') eq 'https';
}


sub host {
    return shift()->req->host();
}


sub hostname {
    return shift()->host();
}


sub server_name {
    return shift()->host();
}


sub server_port {
    my $r=shift();
    if (my $server_ar=$r->{'scope'}{'server'}) {
        return $server_ar->[1];
    }
    return undef;
}


sub client_address {
    return shift()->req->client();
}


sub remote_address {
    return shift()->req->client();
}


sub remote_host {
    return shift()->req->client();
}


sub method {
    return shift()->req->method();
}


sub path_info {
    return shift()->req->path();
}


sub path {
    return shift()->req->path();
}


sub query_string {
    return shift()->req->query_string();
}


sub query_parameters {
    return shift()->req->query_params();
}


sub form_parameters {
    return shift()->req->form_params();
}


sub multipart_parameters {
    return shift()->req->form_params();
}


sub uploads {
    return shift()->req->uploads();
}


sub input {
    return shift()->req->body_stream();
}


sub body {
    my $r=shift();
    return $r->{'body'} if exists $r->{'body'};
    if (my $req=$r->{'req'}) {
        if ($req->can('body')) {
            return $r->{'body'}=$req->body();
        }
        if (my $stream=$req->can('body_stream') ? $req->body_stream() : undef) {
            if ($stream->can('slurp')) {
                return $r->{'body'}=$stream->slurp();
            }
            if ($stream->can('read')) {
                my $buf='';
                while ($stream->read(my $chunk, 8192)) {
                    $buf.=$chunk;
                }
                return $r->{'body'}=$buf;
            }
        }
    }
    return undef;
}


sub content_type {
    my $r=shift();
    return @_ ? $r->{'res'}->content_type(@_) : $r->{'req'}->content_type();
}


sub content_length {
    my $r=shift();
    return @_ ? $r->{'res'}->content_length(@_) : $r->{'req'}->content_length();
}


sub protocol {
    return shift()->req->http_version();
}


sub http_version {
    return shift()->req->http_version();
}


sub status {
    my $r=shift();
    return @_ ? do { $r->{'res'}->status(@_); shift() } : $r->{'res'}->status();
}


sub redirect {
    my $r=shift();
    return $r->{'res'}->redirect(@_);
}


sub headers_in {
    my $r=shift();
    if (@_) {
        return $r->{'req'}->header(@_);
    }
    my $headers_or=$r->{'req'}->headers();
    return HTTP::Headers::Fast->new($headers_or->flatten());
}


sub headers_out {
    my $r=shift();
    my $headers_or=$r->{'headers_out'}
        ||= HTTP::Headers::Fast->new(map { @{$_} } @{$r->{'res'}->headers()});
    if (@_) {
        $r->{'res'}->header(@_);
        return $headers_or->header(@_);
    }
    return $headers_or;
}


sub header_only {
    return (shift()->method() eq 'HEAD');
}


sub request_time {
    return shift()->{'scope'}{'start_time'};
}


sub base {
    return URI->new(shift()->_uri_base())->canonical();
}


sub base_url {
    return URI->new(shift()->_uri_base())->canonical();
}


sub uri {
    my $r=shift();
    return $r->{'_uri'} ||= do {
        my $base=$r->_uri_base();
        my $path=$r->path_info() || '';
        my $qs=$r->query_string();
        $base=~s!/$!! if $path =~ m!^/!;
        my $uri=$base . $path;
        $uri.='?' . $qs if (defined($qs) && length($qs));
        URI->new($uri)->canonical();
    };
}


sub _uri_base {
    my $r=shift();
    my $scheme=$r->scheme() || 'http';
    if (my $host=$r->host()) {
        return sprintf('%s://%s', $scheme, $host);
    }
    if (my $server_ar=$r->{'scope'}{'server'}) {
        return sprintf('%s://%s:%s', $scheme, @{$server_ar});
    }
    return sprintf('%s://localhost', $scheme);
}


sub new {


    #  New PAGI request
    #
    my ($class, %r)=@_;
    debug("$class, r: %s, calller:%s", Dumper(\%r, [caller(0)]));


    #  Require scope
    #
    $r{'scope'} || return err('no PAGI scope supplied');


    #  Try to figure out filename user wants
    #
    unless ($r{'filename'}) {

        #  Not supplied - need to work out
        #
        debug('filename not supplied, determining from request');

        my $fn;
        if (my $dn=($r{'document_root'} || $ENV{'DOCUMENT_ROOT'} || $DOCUMENT_ROOT)) {

            #  Get from URI and location
            #
            my $uri=$r{'req'}->path();
            debug("uri: $uri");
            $fn=File::Spec->catfile($dn, split(m{/+}, $uri));
            debug("fn: $fn from dn: $dn, uri: $uri");

        }

        #  Need to add default psp file ?
        #
        unless ($fn=~WEBDYNE_PSP_EXT_RE) { # fastest

            #  Is it a directory that exists ? Only append default document if that is the case, else let the api code
            #  handle it
            #
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
                    $fn=File::Spec->catfile($fn, split m{/+}, $document_default);
                }
            }
            else {

                #  Not .psp file, do not want
                #
                debug("fn: $fn does not end with /, leaving undef");
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

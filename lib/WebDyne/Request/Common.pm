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
package WebDyne::Request::Common;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA @EXPORT_OK);
use warnings;
no warnings qw(uninitialized once);


#  External modules
#
use Data::Dumper;
use WebDyne::Util;
use B ();
use Exporter qw(import);


# Exports
#
@EXPORT_OK=qw(handler_methods_all handler_methods_check handler_methods_init);


#  Version information
#
$VERSION='2.086_617';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  All done. Positive return
#
1;

#==================================================================================================


sub handler_methods_all {


    #  Return list of methods that should be supported
    #
    my ($self, $type)=@_;
    

    #  Read methods
    #
    my @method_all=(qw(
        accept
        accept_encoding
        accept_language
        args
        as_string
        authority
        authorization
        auth_type
        base
        base_url
        body
        body_handle
        cache_control
        charset
        cleanup_register
        client_address
        content
        content_encoding
        content_length
        content_type
        cookie
        cookies
        custom_response
        cwd
        dir_config
        document_root
        env
        etag
        filename
        finalize
        finfo
        form_parameters
        forwarded_for
        fragment
        handler
        header
        headers
        header_only
        headers_in
        headers_out
        host
        hostname
        https
        http_version
        id
        if_modified_since
        if_none_match
        input
        is_ajax
        is_main
        location
        log_error
        lookup_file
        lookup_uri
        main
        media_type
        method
        mtime
        multipart_parameters
        next
        notes
        origin
        output_filters
        path
        path_info
        path_parameters
        pool
        preferred_charset
        preferred_encoding
        preferred_language
        preferred_media_type
        prev
        print
        protocol
        query_parameters
        query_string
        redirect
        referer
        register_cleanup
        remote_address
        remote_host
        remote_port
        remote_user
        request_time
        route
        run
        scheme
        script_name
        secure
        sendfile
        send_http_header
        server_name
        server_port
        session
        session_id
        set_handlers
        status
        status_line
        unparsed_uri
        uploads
        uri
        url
        user
        user_agent
        write
        err_html
        DESTROY
    ));

    return \@method_all;
    
}
            

sub handler_methods_check {


    #  Check all methods have been defined in handler
    #
    my ($class, $method_hr)=@_;
    
    
    #  Make sure we don't have more methods defined here than we need
    #
    my %method_class=%{$method_hr};
    my @method_package=grep { $_ eq lc($_) } grep { defined *{sprintf('%s::%s', $class, $_)}{'CODE'} } keys %{sprintf('%s::', $class)};
    my %method_package=map { $_=>1 } @method_package;
    map { delete $method_package{$_} } keys %method_class;
    my @method_orphan;
    foreach my $method (keys %method_package) {
    
        #  Skip new, init and any private methods that start with _
        next if grep { $method eq $_ } qw(new init err_html res req sse ws);
        next if $method=~/^_/;;
        
        if (my $cr=*{sprintf('%s::%s', $class, $method)}{'CODE'}) {
            if (my $gv=B::svref_2object($cr)->GV) {
                if ($gv->STASH->NAME eq $class) {
                    push @method_orphan, $method;
                }
            }
        }
    }
    if (@method_orphan) {
        warn(sprintf("orphan methods in class: $class, %s", Dumper(\@method_orphan)));
        #sleep 1;
    }
        

    #  Check we haven't missed any defining any methods
    #
    %method_class=%{$method_hr};
    foreach my $method (sort @{&handler_methods_all}) {
        unless (defined(delete($method_class{$method}))) {
            warn "missing method definition: $method in class: $class";
            #sleep 1;
        }
        unless ($class->can($method)) {
            warn "missing method function: $method in class: $class";
            #sleep 1;
        }
    }
    if (keys(%method_class)) {
        warn(sprintf("extra methods in class: $class, %s", Dumper([keys %method_class])));
        #sleep 1;
    }
    1;
    
}


sub handler_methods_init {

    my ($class, $handler, $method_hr)=@_;
    
    my %method_check;
    foreach my $method (sort keys %{$method_hr}) {
        my $dispatch=$method_hr->{$method};
        debug("method: $method, dispatch: $dispatch");
        $method_check{$method}++;
        if (ref($dispatch) eq 'CODE') {

            if (defined(*{sprintf('%s::%s', __PACKAGE__, $method)}{'CODE'})) {
                #  Do nothing, defined here
                #
                debug("skip $method, defined in this package");
            }
            else {
                debug("setting method: $method to code ref: $dispatch");
                *{"${class}::${method}"}=$dispatch;
            }

        }
        elsif (!defined($dispatch)) {
            #  Do nothing, will fall through to Fake
            #
            debug("skip $method, will inherit from Fake");
            *{"${class}::${method}"}=\&{"WebDyne::Request::Fake::${method}"};
        }
        else {
            #  Class request method
            #
            debug("setting method: $method to $handler: $dispatch");
            if ($handler->can($dispatch)) {
                *{"${class}::${method}"}=sub { shift()->{'req'}->$dispatch(@_) };
            }
            else {
                die "unsupported request method: $dispatch";
            }
        }
    }
    
    return handler_methods_check($class, \%method_check);
    
}
    
1;

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
package WebDyne::CGI::Simple;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION @ISA);
use warnings;
no warnings qw(uninitialized redefine once);


#  WebDyne Modules
#
use WebDyne::Constant;
use WebDyne::Util;


#  External modules
#
use Data::Dumper;
use Hash::MultiValue;
use CGI::Simple;
$CGI::Simple::MOD_PERL=0;
@ISA=qw(CGI::Simple);
*CGI::Simple::_mod_perl=sub {};


#  Version information
#
$VERSION='2.082_608';


#  CGI upload vars
#
$CGI::Simple::DISABLE_UPLOADS=$WEBDYNE_CGI_DISABLE_UPLOADS;
$CGI::Simple::POST_MAX=$WEBDYNE_CGI_POST_MAX;


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#==============================================================================

sub new {


    #  New instance of WebDyne::CGI::Common
    #
    my ($class, $r, %param)=@_;
    debug("class: $class, r: $r, param: %s, caller %s", Dumper(\%param, [caller(0)]));
    
    
    #  Get from cache or construct
    #
    my $cgi_or;
    unless ($cgi_or=$r->{'_CGI'}) {
        
        
        #  Need to construct
        #
        if (($r->headers_in('content-type') eq 'application/x-www-form-urlencoded') && $r->content_length()) {
        
            #  Normal form POST so can read body in 
            #
            debug('detected application/x-www-form-urlencoded form submission, reading body');
            my $body=$r->body();
            local $ENV{'REQUEST_METHOD'} ||= ($r->method() || 'POST');
            debug("args: %s, body:$body", $r->args);
            $cgi_or=CGI::Simple->new(join('&', grep {$_} $r->args, $body));
        }
        elsif ($r->content_length()) {
        
            #  Need to read in some other POST content, e.g. file upload. Need to manipulate CGI::Simple internals here, pretty ugly.
            #
            my $fh=$r->input();
            debug('detected other POST submission, reading body from %s', $fh);
            local $ENV{'REQUEST_METHOD'}='GET';
            $cgi_or=CGI::Simple->new($r->args);
            local $ENV{'CONTENT_LENGTH'} ||= $r->content_length();
            local $ENV{'CONTENT_TYPE'} ||= ($r->headers_in('Content-Type') || 'multipart/form-data');
            local $ENV{'REQUEST_METHOD'} ||= ($r->method() || 'POST');
            debug('fh: %s, content_length: %s, content_type: %s, request_method: %s', $fh, @ENV{qw(CONTENT_LENGTH CONTENT_TYPE REQUEST_METHOD)});
            local *STDIN=$fh;
            $cgi_or->_parse_multipart($fh);
        }
        else {
        
            #  Don't need POST body, just get query param args
            #
            debug('non POST submissions, just using args: %s', $r->args);
            local $ENV{'REQUEST_METHOD'} ||= ($r->method() || 'GET');
            $cgi_or=CGI::Simple->new($r->args);
        }

    }
        
    
    #  Add any param
    #
    map { $cgi_or->param($_, $param{$_}) } keys %param;
    debug("cgi_or: $cgi_or, %s", Dumper($cgi_or));
    

    #  Bless and return
    #
    return bless($cgi_or, __PACKAGE__);
    
}


sub Vars {

    #  Simulate Plack::Request Hash::MultiValue response
    #
    my ($self, $hr)=@_;
    if ($hr) {
        
        #  Pushing back into CGI
        #
        $self->delete_all();
        foreach my $param (keys %{$hr}) {
            $self->param($param, $hr->get_all($param));
        }
        return $hr;
        
    }
    else {
        my @pairs;
        foreach my $param ($self->param()) {
            my @values=$self->param($param);
            map { push @pairs, ( $param => $_ ) } @values;
        }
        $hr=Hash::MultiValue->new(@pairs)
    }

    return wantarray ? %{$hr} : $hr

}


sub env {

    return \%ENV
    
}


sub upload {

    local $ENV{'CONTENT_TYPE'}='multipart/form-data';
    return shift()->SUPER::upload(@_);
    
}


sub uploads {

    #  Replicate Plack::Request::Uploads->uploads()
    #
    my $self=shift();
    my @pairs;
    foreach my $param ($self->param()) {
        
        my @fn = $self->upload();
        debug('fn: %s', Dumper(\@fn));
        next unless @fn;

        foreach my $fn (@fn) {
            next unless $fn;  # skip undef
            my $fh = $self->upload($fn);
            my $upload_or = WebDyne::CGI::Simple::Upload->new(
                filename => $fn,
                size     => $self->{'.tmpfiles'}{$fn}{'size'},
                mime     => $self->{'.tmpfiles'}{$fn}{'mime'},
                fh       => $fh,
            );
            push @pairs, ($param => $upload_or);
        }
    }
    debug('pairs: %s', Dumper(\@pairs));

    return Hash::MultiValue->new(@pairs);
}


#  Emulate Plack::Request::Upload object
#
package WebDyne::CGI::Simple::Upload;

use strict;
use File::Basename qw(basename);

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}
sub filename { $_[0]->{'filename'} }
sub size     { $_[0]->{'size'} }
sub content  {
    my $self = shift;
    seek ($self->{'fh'}, 0, 0);
    local $/;
    my $fh=$self->{'fh'};
    return <$fh>;
}
sub fh       { $_[0]->{'fh'} }
sub path     { $_[0]->{'fh'} }
sub content_type { $_[0]->{'mime'} }
sub basename { basename($_[0]->{'filename'}) }

1;

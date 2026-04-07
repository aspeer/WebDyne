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
package WebDyne::CGI;


#  Pragma
#
use strict qw(vars);
use vars   qw($VERSION $AUTOLOAD);
use warnings;
no warnings qw(uninitialized redefine);


#  WebDyne Modules
#
use WebDyne::Util;
use WebDyne::CGI::Simple;


#  External modules
#
use Data::Dumper;


#  Version information
#
$VERSION='2.077_597';


#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#==============================================================================

sub new {

    
    #  Setup universal CGI object for return
    #
    my ($class, $r, %param)=@_;
    debug("class: $class, r:$r, caller: %s", Dumper([caller(0)]));


    #  Only generate if not already done
    #
    my $cgi_or=($r->{'_CGI'} ||= do {
    
        #  Take forms and STDIN content into account
        #
        if (($r->headers_in('content-type') eq 'application/x-www-form-urlencoded') && $r->content_length()) {
            my $body=$r->body();
            WebDyne::CGI::Simple->new($r, $r->args, $body);
        }
        elsif ($r->content_length()) {
            my $cgi_or=WebDyne::CGI::Simple->new($r, $r->args);
            local $ENV{'CONTENT_LENGTH'} ||= $r->content_length();
            local $ENV{'CONTENT_TYPE'} ||= $r->headers_in('Content-Type');
            local *STDIN=$r->input();
            $cgi_or->_parse_multipart($r->input());
            $cgi_or;
        }
        else {
            WebDyne::CGI::Simple->new($r, $r->args);
        }
    });
    return $cgi_or;

}

1;

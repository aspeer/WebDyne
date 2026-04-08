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


#
#
package WebDyne::PSGI::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;
no warnings qw(once);


#  External modules
#
use File::Basename;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Version information
#
$VERSION='2.083_610';



#  Hash of constants
#  <<<
%Constant=(

    
    #  Document Root, usually supplied as env var or command line option but
    #  can be set here.
    #
    DOCUMENT_ROOT	=> undef,
    
    
    #  Document default - will be served if exists in DOCUMENT_ROOT and no other
    #  file specified.
    #
    DOCUMENT_DEFAULT	=> 'app.psp',
    
    
    #  File to use for indexing
    #
    WEBDYNE_PSGI_INDEX	=> 'index.psp',
    
    
    #  Middeware config, static module. Loaded by default for convenience if
    #  started via webdyne.psgi script directly (i.e. not invoked by plakup
    #  or starman). Activate in middleware section below if wanted with plackup
    #  or starman
    #
    #  Serve any static file except .psp
    #
    #WEBDYNE_PSGI_MIDDLEWARE_STATIC => qr{^(?!.*\.psp$).*\.\w+$},
    #
    #  Just common files
    #
    WEBDYNE_PSGI_MIDDLEWARE_STATIC => qr{\.(?:css|js|jpg|jpeg|png|gif|svg|ico|woff2?|ttf|eot|otf|webp|map|txt|inc|htm|html)$}i,
    
    
    #  Serve static files ?
    #
    WEBDYNE_PSGI_STATIC => 1,
    
    
    #  All other middleware. Uncomment/modify as required
    #
    WEBDYNE_PSGI_MIDDLEWARE => [
        
        #[ 'Debug' => 
        #    { enabled => 1 } 
        #],
        
        #  If given as a sub code ref then option hash ref is first param 
        #
        [ 'Static' => sub { 
            { path=>$WebDyne::PSGI::WEBDYNE_PSGI_MIDDLEWARE_STATIC, root=>(-f $_[0]->{'root'}) ? dirname($_[0]->{'root'}) : $_[0]->{'root'}, pass_through=>1 }
        }]
        
        
    ],
    
    
    #  Environment variables to keep, needs to be array ref
    #
    WEBDYNE_PSGI_ENV_KEEP => [qw(DOCUMENT_ROOT DOCUMENT_DEFAULT)],
    WEBDYNE_PSGI_ENV_SET  => {},
    
    
    #  Warn on error ?
    #
    WEBDYNE_PSGI_WARN_ON_ERROR => undef,


);
# >>>


#  Done
#
1;
__END__


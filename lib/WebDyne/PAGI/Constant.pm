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
package WebDyne::PAGI::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %Constant);
use warnings;


#  Does the heavy liftying of importing into caller namespace
#
require WebDyne::Constant;
@ISA=qw(WebDyne::Constant);


#  Version information
#
$VERSION='2.075';



#  Hash of constants
#  <<<
%Constant=(

    
    #  Middeware config, static module. Loaded by default for convenience if
    #  started via webdyne.pagi script directly
    #
    #  Serve any static file except .psp
    #
    #WEBDYNE_PSGI_MIDDLEWARE_STATIC => qr{^(?!.*\.psp$).*\.\w+$},
    #
    #  Just common files
    #
    WEBDYNE_PAGI_MIDDLEWARE_STATIC => qr{\.(?:css|js|jpg|jpeg|png|gif|svg|ico|woff2?|ttf|eot|otf|webp|map|txt|inc|htm|html)$}i,
    
    
    #  All other middleware. Uncomment/modify as required
    #
    WEBDYNE_PAGI_MIDDLEWARE => [
        
        #{ 'Debug' => 
        #    { panels => [ qw(Environment) ] } 
        #},
        
        #  If given as a sub code ref the $DOCUMENT_ROOT is first param 
        #
        #{ 'Static' => sub { 
        #    { path=>qr{^(?!.*\.psp$).*\.\w+$}, root=>shift() }
        #}}
        
    ],
    
    
    #  Environment variables to keep, needs to be array ref
    #
    WEBDYNE_PAGI_ENV_KEEP => [qw(DOCUMENT_ROOT DOCUMENT_DEFAULT)],
    WEBDYNE_PAGI_ENV_SET  => {},
    
    
    #  Warn on error ?
    #
    WEBDYNE_PAGI_WARN_ON_ERROR => undef,
    
    
    #  Modules to load on eval
    #
    WEBDYNE_PAGI_EVAL_PREPEND => << 'END'
use Future::AsyncAwait;
use Future::IO;
*err=sub { die sprintf(shift, @_) || 'undefined error' };
*WebDyne::err=\&err;
END
,


);
# >>>


#  Done
#
1;
__END__


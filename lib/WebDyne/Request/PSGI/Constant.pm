#
#  This file is part of WebDyne.
#
#  This software is copyright (c) 2025 by Andrew Speer <andrew.speer@isolutions.com.au>.
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
package WebDyne::Request::PSGI::Constant;


#  Pragma
#
use strict qw(vars);
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
use warnings;


#  Version information
#
$VERSION='2.004_224';


#  Get module file name and path, derive name of file to store local constants
#
use Cwd qw(abs_path);
my $local_fn=abs_path(__FILE__) . '.local';


#  Hash of constants
#  <<<
%Constant=(

    
    #  Document Root
    #
    DOCUMENT_ROOT	=> undef,
    
    
    #  Document default
    #
    DOCUMENT_DEFAULT	=> 'index.psp',
    
    
    #  Dir Config
    #
    WEBDYNE_PSGI_DIR_CONFIG => undef,
    
    
    #  Warn on error ?
    #
    WEBDYNE_PSGI_WARN_ON_ERROR => undef,


    #  Local constants override anything above
    #
    #%{do($local_fn) || {}},
    #$%{do([glob(sprintf('~/.%s.local', __PACKAGE__))]->[0]) || {}}    # || {} avoids warning

);
# >>>


sub import {
    
    goto &WebDyne::Constant::import;
    
}


#  Export constants to namespace, place in export tags
#
require Exporter;
require WebDyne::Constant;
@ISA=qw(Exporter WebDyne::Constant);
+__PACKAGE__->local_constant_load(\%Constant);
%Constant=(
    %Constant,
    %{do($local_fn) || {}},
    %{do([glob(sprintf('~/.%s.local', __PACKAGE__))]->[0]) || {}} 
);
foreach (keys %Constant) {${$_}=($Constant{$_}=$ENV{$_} || $Constant{$_})}
@EXPORT=map {'$' . $_} keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);


#  All done, init finished
#
1;
#===================================================================================================

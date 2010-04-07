#
#
#  Copyright (c) 2003 Andrew W. Speer <andrew.speer@isolutions.com.au>. All rights 
#  reserved.
#
#  This file is part of WebDyne.
#
#  WebDyne is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program; if not, write to the Free Software
#  Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
#

#
#  WebDyne::Err Constants
#
package WebDyne::Err::Constant;
use strict qw(vars);
use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);
no warnings qw(uninitialized);
local $^W=0;


#  Need the File::Spec module
#
use File::Spec;


#  Version information
#
$VERSION='1.008';


#  Hash of constants
#
%Constant = (


    #  Where we keep the error template
    #
    WEBDYNE_ERR_TEMPLATE	=>  File::Spec->catfile(&class_dn(__PACKAGE__), 'error.psp'),


    #  If set to 1, error messages will be sent as text/plain, not
    #  HTML. If ERROR_EXIT set, child will quit after an error
    #
    WEBDYNE_ERROR_TEXT		=>  0,
    WEBDYNE_ERROR_EXIT		=>  0,



);


sub class_dn {


    #  Get class dir
    #
    my $class=shift();


    #  Get package file name so we can look up in inc
    #
    (my $class_fn="${class}.pm")=~s/::/\//g;
    $class_fn=$INC{$class_fn} ||
	die("unable to find location for $class in \%INC");


    #  Split
    #
    my $class_dn=(File::Spec->splitpath($class_fn))[1];

}



#  Export constants to namespace, place in export tags
#
require Exporter;
require WebDyne::Constant;
@ISA=qw(Exporter WebDyne::Constant);
+__PACKAGE__->local_constant_load(\%Constant);
foreach (keys %Constant) { ${$_}=$Constant{$_} }
@EXPORT=map { '$'.$_ } keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;

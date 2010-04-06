#
#
#  Copyright (c) 2003 Andrew W. Speer <andrew.speer@isolutions.com.au>. All rights 
#  reserved.
#
#  This file is part of WebDyne::Install.
#
#  WebDyne::Install is free software; you can redistribute it and/or modify
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
#  $Id: Constant.pm,v 1.30 2007/07/07 08:05:23 aspeer Exp $

#
#  Constants
#
package WebDyne::Install::Constant;


#  Pragma
#
use strict qw(vars);


#  Vars to use
#
use vars qw($VERSION $REVISION @ISA %EXPORT_TAGS @EXPORT_OK @EXPORT %Constant);


#  External Modules
#
use File::Path;
use File::Spec;


#  Version information in a format suitable for CPAN etc. Must be
#  all on one line
#
$VERSION='1.005';

#  Revision information, auto maintained by CVS
#
$REVISION=(qw$Revision: 1.30 $)[1];


#------------------------------------------------------------------------------


#  Work out default cache directory location if none spec'd by user and
#  no PREFIX supplied
#
my $cache_default_dn;


#  Windows ?
#
if ($^O=~/MSWin[32|64]/) {
    $cache_default_dn=File::Spec->catdir($ENV{'SYSTEMROOT'}, qw(TEMP webdyne))
}
#  No - set to /var/cache/webdyne
#
else {
    $cache_default_dn=File::Spec->catdir(
        File::Spec->rootdir(), qw(var cache webdyne));
}



#  Real deal
#
%Constant = (


    #  Where perl5 library dirs are sourced from
    #
    FILE_PERL5LIB			  =>  'perl5lib.pl',
    
    
    #  Default cache directory
    #
    DIR_CACHE_DEFAULT			  =>  $cache_default_dn


   );


#  Finalise and export vars
#
require Exporter;
require WebDyne::Constant;
@ISA=qw(Exporter WebDyne::Constant);
#  Local constants override globals
+__PACKAGE__->local_constant_load(\%Constant);
foreach (keys %Constant) { ${$_}=$Constant{$_} }
@EXPORT=map { '$'.$_ } keys %Constant;
@EXPORT_OK=@EXPORT;
%EXPORT_TAGS=(all => [@EXPORT_OK]);
$_=\%Constant;

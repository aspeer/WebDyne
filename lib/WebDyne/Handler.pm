#
#
#  Copyright (c) 2003 Andrew W. Speer <andrew.speer@isolutions.com.au>. All rights 
#  reserved.
#
#  This file is part of WebDyne::Handler.
#
#  WebDyne::Handler is free software; you can redistribute it and/or modify
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
#  $Id: Handler.pm,v 1.1.1.1 2008/03/22 03:44:55 aspeer Exp $
#
package WebDyne::Handler;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION $REVISION);


#  WebDyne Modules.
#
use WebDyne::Constant;
use WebDyne::Base;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION = eval { require WebDyne::VERSION; do $INC{'WebDyne/VERSION.pm'}};


#  Release information
#
$REVISION= (qw$Revision: 1.1.1.1 $)[1];


#  Debug 
#
debug("%s loaded, version $VERSION, revision $REVISION", __PACKAGE__);


#  And done
#
1;

#------------------------------------------------------------------------------


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my ($class, @param)=@_;
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->() || return;
    my %param=(@param==1) ? (handler => @param) : @param;
    $self->set_handler($param{'handler'});

}

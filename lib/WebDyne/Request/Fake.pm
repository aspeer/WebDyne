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
package WebDyne::Request::Fake;


#  Compiler Pragma
#
use strict	qw(vars);
use vars	qw($VERSION $AUTOLOAD);


#  External modules
#
use Cwd qw(cwd);
use Data::Dumper;
use HTTP::Status (RC_OK);


#  Version information
#
$VERSION='1.004';

#  Debug load
#
debug("Loading %s version $VERSION", __PACKAGE__);


#  All done. Positive return
#
1;


#==================================================================================================


sub dir_config {

    my ($r, $key)=@_;
    return $ENV{$key};

}


sub filename {

    my $r=shift();
    File::Spec->rel2abs($r->{'filename'}, cwd());

}


sub headers_out {

    my $r=shift();
    $r->{'headers_out'} ||= { 'Content-Type'=>'text/html' };

}


sub headers_in {

    my $r=shift();
    $r->{'headers_in'} ||= {};

}


sub is_main {

    my $r=shift();
    $r->{'main'} ? 0 : 1;

}


sub log_error {

    shift(); warn(@_);

}


sub lookup_file {

    my ($r, $fn)=@_;
    my $r_child=ref($r)->new( filename=> $fn ) || return err();

}


sub lookup_uri {

    my ($r, $uri)=@_;
    my $fn=File::Spec::Unix->catfile((File::Spec->splitpath($r->filename()))[1], $uri);
    return $r->lookup_file($fn);

}


sub main {

    my $r=shift();
    @_ ? $r->{'main'}=shift() : $r->{'main'} || $r;

}


sub new {

    my ($class, %r)=@_;
    return bless \%r, $class;

}


sub notes {

    my ($r,$k,$v)=@_;
    if (@_==3) {
	return $r->{'_notes'}{$k}=$v
    }
    elsif (@_==2) {
	return $r->{'_notes'}{$k}
    }
    elsif (@_==1) {
	return ($r->{'_notes'} ||= {});
    }
    else {
	return err('incorrect usage of %s notes object, r->notes(%s)', +__PACKAGE__, join(',', @_[1..$#_]));
    }

}


sub parsed_uri {

    my $r=shift();
    require URI;
    URI->new($r->uri());

}


sub prev {

    my $r=shift();
    @_ ? $r->{'prev'}=shift() : $r->{'prev'};

}


sub print {

    my $r=shift();
    CORE::print((ref($_[0]) eq 'SCALAR') ? ${$_[0]} : @_);

}


sub register_cleanup {

    my $r=shift();
    push @{$r->{'register_cleanup'} ||= []}, @_;

}


sub run {

    my ($r, $self)=@_;
    ref($self)->handler($r);

}


sub status {

    my $r=shift();
    @_ ? $r->{'status'}=shift() :  $r->{'status'} || RC_OK;

}


sub uri {

    shift()->{'filename'}

}


sub debug {


}


sub AUTOLOAD {

    my ($r,$v)=@_;
    my $k=($AUTOLOAD=~/([^:]+)$/) && $1;
    #warn(sprintf("Unhandled '%s' method, using AUTOLOAD", $k)); 
    $v ? $r->{$k}=$v : $r->{$k};


}


sub DESTROY {

    my $r=shift();
    if (my $cr_ar=delete $r->{'register_cleanup'}) {
	foreach my $cr (@{$cr_ar}) {
	    $cr->($r);
	}
    }
}

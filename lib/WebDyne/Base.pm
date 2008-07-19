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
package WebDyne::Base;


#  Compiler Pragma
#
sub BEGIN	{ $^W=0 };
use strict	qw(vars);
use vars	qw($VERSION @EXPORT);
use warnings;
no  warnings	qw(uninitialized redefine once);


#  External modules
#
use Data::Dumper;
use IO::File;


#  Use Exporter
#
require Exporter;


#  Exports
#
@EXPORT=qw(err errstr errclr errdump errsubst errstack errnofatal);


#  Version information. Must be all on one line
#
$VERSION = eval { require WebDyne::VERSION; do $INC{'WebDyne/VERSION.pm'}};


#  Var to hold package wide hash, for data shared across package, and error stack
#
my (%Package, @Err);


#  All done. Positive return
#
1;


#==================================================================================================


sub import {


    #  Get message
    #
    my ($message, @param)=@_;


    #  Get who is calling us
    #
    my $caller=(caller(0))[0] || return undef;


    #  fh we will write to
    #
    my $debug_fh;


    #  Environment var overrides all
    #
    if ($ENV{'PERL_DEBUG'} || $ENV{'PERL_DEBUG_ALL'}) {


	#  fh is stderr
	#
	$debug_fh=\*STDERR;


    }
    elsif (ref(my $debug_hr=${"${caller}::DEBUG"}) eq 'HASH') {


	#  Debug is hash ref, extract filename etc and open
	#
	my ($fn, $mode, $package)=@{$debug_hr}{qw(filename mode package)};
	$fn ||= $debug_hr->{'file'}; #Alias
	if ($fn && ($package ? ($package eq $caller) : 1)) {
	    $mode ||= O_CREAT|O_APPEND|O_WRONLY;
	    $debug_fh=($Package{'debug_fh'}{$fn} ||= (
		IO::File->new($fn,$mode) || do {
		    warn("unable to open file '$fn', $!");
		    undef;
		}));
	}
	elsif (!$fn) {
	    warn(sprintf('no file name specified in DEBUG hash %s', Dumper($debug_hr)));
	}

    }
    elsif (!ref(my $fn=${"${caller}::DEBUG"}) && ${"${caller}::DEBUG"}) {

	#  Just file name spec'd. Open
	#
	$debug_fh=(
	    $Package{'debug_fh'}{$fn} ||= (
		IO::File->new($fn, O_CREAT|O_APPEND|O_WRONLY) || do {
		    warn("unable to open file '$fn', $!");
		    undef;
		}));
    }


    #  After all that did we get a file handle ? If so, import the debug handler
    #
    if ($debug_fh) {

	#  Yes, setup debug routine
	#
	$debug_fh->autoflush(1);
	*{"${caller}::debug" }= sub {
	    local $|=1;
	    my $method=(caller(1))[3] || 'main';
	    (my $subroutine=$method)=~s/^.*:://;
	    if ($ENV{'PERL_DEBUG'} && (($caller eq $ENV{'PERL_DEBUG'}) || ($method eq $ENV{'PERL_DEBUG'}))) {
		CORE::print $debug_fh "[$subroutine] ", sprintf(shift(), @_), $/;
	    }
	    elsif (!$ENV{'PERL_DEBUG'}) {
		CORE::print $debug_fh "[$subroutine] ", sprintf(shift(), @_), $/;
	    }
	} unless UNIVERSAL::can($caller, 'debug');
	*{"${caller}::Dumper"}=\&Data::Dumper::Dumper
	    unless UNIVERSAL::can($caller, 'Dumper');

    }
    else {


	#  No, null our debug and Dumper routine
	#
	*{"${caller}::debug" }= sub {} unless UNIVERSAL::can($caller, 'debug');
	*{"${caller}::Dumper"}= sub {} unless UNIVERSAL::can($caller, 'Dumper');

    };


    #  Setup file handle for error backtrace
    #
    if (my $fn=${"${caller}::ERROR"}) {

	#  Just file name spec'd. Log
	#
	$Package{'error_fn'}{$fn}++

    }


    #  Done
    #
    goto &Exporter::import;

}


sub errnofatal {


    #
    #
    @_ ? $Package{'nofatal'}=@_ : $Package{'nofatal'};


}


sub err {


    #  Get the message and any sprintf params
    #
    my ($message, @param)=@_;


    #  If no message supplied return last one seen
    #
    unless ($message) {
	$message=@Err ? $Err[$#Err]->[0] && return undef :  'undefined error';
    }
    else {
	$message=sprintf($message, @param);
    }


    #  Init the caller var and array
    #
    my @caller;
    my $caller=(caller(0))[0];


    #  Populate the caller array
    #
    for (my $i=0; my @info=(caller($i))[0..3]; $i++) {


	#  Push onto the caller array
	#
	push @caller, \@info;


    }


    #  If this message is *not* the same as the last one we saw,
    #  we will log it
    #
    unless ($message eq (@Err && $Err[0]->[0])) {


        #  Add to stack
        #
        unshift @Err, [$message, @caller];


	#  If caller has a debug function enabled, call this with the warning
	#
	if (UNIVERSAL::can($caller, 'debug')) {


	    #  Yes, they are using the debug module, so can we call it
	    #
	    &{"${caller}::debug"}($message);


	}


	#  Dump to backtrace file if enabled
	#
	foreach my $fn (keys %{$Package{'error_fn'}}) {

	    unless (my $fh=IO::File->new($fn, O_CREAT|O_APPEND|O_WRONLY)) {
		warn("unable to open file '$fn', $!");
	    }
	    else {
		seek($fh,0,2); # Seek to EOF
		my $errdump=&errdump();
		CORE::print $fh $errdump, $/,$/;
		$fh->close();
	    }

	}


    }


    #  Return undef
    #
    return $Package{'nofatal'} ? undef : die(&errdump);

}


sub errstr {


    #  Check that there are messages in the stack before trying to get
    #  the last one
    #
    if (my $count=@Err) {


	#  There are objects in the array, so it is safe to do a fetch
	#  on the last (-1) array slot
	#
	my $errstr=$Err[--$count]->[0];


	#  And return the errstr
	#
	return $errstr;

    }
    else {


	#  Nothing in the array stack, return undef
	#
	return undef;


    }

}


sub errclr {


    #  Clear the warning stack
    #
    undef @Err;


    #  Replace errors if args
    #
    @_ && (return &err(@_));


    #  Return OK always
    #
    return 1;

}


sub errsubst {


    #  Replace the current error message with a new one, keeping callback
    #  stack
    #
    my ($message, @param)=@_;


    #  If no message supplied return last one seen
    #
    unless ($message) {
	$message=@Err ? $Err[$#Err]->[0] && return undef :  'undefined error';
    }
    else {
	$message=sprintf($message, @param);
    }

    #  Chomp the message
    #
    chomp($message);


    #  Replace if present, define if not
    #
    @Err ? ($Err[$#Err]->[0] = $message) : goto &err;


    #  Return
    #
    return undef;


}


sub errdump {


    #  Use can send additional info to dump as key/value pairs in hash ref
    #  supplied as arg
    #
    my $info_hr=shift();


    #  Return a dump of error in a nice format, no params. Do this with
    #  format strings, so define the ones we will use
    #
    my @format=(

	'+' . ('-' x 78) .  "+\n",
	"| @<<<<< | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<< |\n",
	"|        | ^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<~~ |\n"

       );


    #  Go through the message stack on error at a time in reverse order
    #
    foreach my $err_ar (reverse @Err) {


	#  Get message, clean up
	#
	my $message=ucfirst($err_ar->[0]);
	$message=~s/\s+$//;
	$message.='.' unless $message=~/[\.\!\?]$/;


	#  Print out date, time, error message
	#
	formline $format[0];
	formline $format[1], 'Date', scalar(localtime());
	formline $format[0];
	formline $format[1], 'Error', $message;
	(formline $format[2], $message) if $message;
	formline $format[0];


	#  Flag so we know we have printed the caller field
	#
	my $caller_fg;


	#  Go through callback stack
	#
	for (my $i=1; defined($err_ar->[$i]); $i++) {


	    #  Get method, line no and file
	    #
	    my $method=$err_ar->[$i+1][3] || $err_ar->[$i][0] ||  last;
	    my $lineno=$err_ar->[$i][2] || next;
	    my $filenm=$err_ar->[$i][1];


	    #  Print them out, print out caller label unless we
	    #  have already done so
	    #
	    formline $format[1],
	    $caller_fg ++ ? '' : 'Caller' , "$method, line $lineno";

	}


	#  Include any user supplied info
	#
	while (my ($key, $value)=each %{$info_hr}) {


	    #  Print separator, info
	    #
	    formline $format[0];
	    formline $format[1], $key, $value;
	    (formline $format[2], $value) if $value;

	}


	#  Finish off formatting, print PID. Dont ask me why $$ has to be "$$",
	#  it does not show up any other way
	#
	formline $format[0];
	formline $format[1], 'PID', "$$";
	formline $format[0];
	formline "\n";


    }


    #  Empty the format accumulator and return it
    #
    my $return=$^A; undef $^A;
    return $return;

}


sub errstack {

    #  Return the raw error stack
    #
    return \@Err;

}



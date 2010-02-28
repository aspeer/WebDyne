#
#
#  Copyright (c) 2003 Andrew W. Speer <andrew.speer@isolutions.com.au>. All rights 
#  reserved.
#
#  This file is part of WebDyne::Err.
#
#  WebDyne::Err is free software; you can redistribute it and/or modify
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
package WebDyne::Err;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);


#  Webmod Modules.
#
use WebDyne::Constant;
use WebDyne::Err::Constant;
use WebDyne::Base;


#  External modules
#
use HTTP::Status qw(is_success is_error RC_INTERNAL_SERVER_ERROR);
use File::Spec;


#  Version information in a formate suitable for CPAN etc. Must be
#  all on one line
#
$VERSION = eval { require WebDyne::VERSION; do $INC{'WebDyne/VERSION.pm'}};


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  Package wide vars
#
my %Package;
*debug=\&WebDyne::debug;


#  And done
#
1;


#------------------------------------------------------------------------------


sub err_html {


    #  Output errors to browser.
    #
    my ($self, $errstr)=@_;
    $errstr=sprintf($errstr, @_[2..$#_]);


    #  Debug
    #
    debug("in error routine self $self, errstr $errstr");


    #  Get errstr from stack if not supplied, or add if it
    #  has been
    #
    $errstr ? err($errstr) : ($errstr=errstr() || do {err($_='undefined error from handler'); $_});
    debug("final errstr $errstr");


    #  Try to get CGI object from class, or create if not present - may
    #  not have been initialised before error occured); Same with request
    #  object, not fatal if not present. Also make sure we get main 
    #  request object for error handling
    #
    my ($r, $cgi_or);
    if ($r=eval { $self->{'_r'} }) {


	#  Get main request handler in case we are in subrequest
	#
	$r=$r->main() || $r;


	#  Get CGI object
	#
	$cgi_or=$self->{'_CGI'} || CGI->new();

    }
    debug("r $r, cgi_or $cgi_or");


    #  Print errstr and exit immediately if  no request object yet, or in error loop
    #
    if (!$r) {
	print(errdump());
	CORE::exit 0;
    };


    #  Log the error
    #
    $r->log_error($errstr);


    #  Status must be internal error
    #
    $r->status(RC_INTERNAL_SERVER_ERROR);


    #  Do not run any more handlers
    #
    $r->set_handlers( PerlHandler=>undef );


    #  Kill this Apache process afterwards to make sure it does not behave
    #  badly after this error, if that is what the user has configured
    #
    if ($WEBDYNE_ERROR_EXIT) {
	my $cr=sub { CORE::exit() };
	$MP2 ? $r->pool->cleanup_register($cr) : $r->register_cleanup($cr);
    }


    #  Error can be text or HTML, must be text if in Safe eval mode
    #
    if ($WEBDYNE_ERROR_TEXT || $WEBDYNE_EVAL_SAFE || $self->{'_error_handler_run'}++ || !$cgi_or) {


	#  Text error, set content type
	#
	debug("using text error - update $r content_type");
	$r->content_type('text/plain');


	#  Push error
	#
	my $err_text=errdump({

	    'URI'  =>	$r->uri()

	   });


	#  Clear error stack and $@.
	#
	errclr(); eval { undef } if $@;


	#  Print error and return
	#
	$r->send_http_header() if !$MP2;
        $r->print($err_text);
        return &Apache::OK;


    }
    else {


	#  Get error paramaters, must make copy of stack, it will be erased.
	#
	debug('using html error');
	my @errstack=@{&errstack()};
	my %param=(

	    errstr	=> $errstr,
	    errstack_ar	=> \@errstack,
	    r		=> $r,

	   );


	#  Clear error stack and $@ so this render works without errors
	#
	errclr(); eval { undef } if $@;


	#  Wrap everything in eval block in case this error was thrown interally by
	#  WebDyne not being able to load/start etc, in which case trying to run it
	#  again won't be helpful
	#
        my $status;
	eval {


	    #  Only compile container once if we can help it
	    #
            local $SIG{__DIE__}=undef;
	    require WebDyne::Compile;
	    my $container_ar=($Package{'container_ar'} ||= &WebDyne::Compile::compile($self,{

		srce	=> $WEBDYNE_ERR_TEMPLATE,
		nofilter	=> 1

	       })) || return $self->err_html('fatal problem in error handler during compile !');


	    #  Get the data portion of the container (meta info not needed) and render. Bit of cheating
	    #  to use internal
	    #
	    my $data_ar=$container_ar->[1];
	    my $html_sr=$self->render({

		data    => $data_ar,
		param   => \%param

	       }) || return $self->err_html('fatal problem in error handler during render !');


	    #  Set custom handler
	    #
	    $status=$r->status();
	    debug("send custom response for status $status on r $r");
	    $r->custom_response($status, ${$html_sr});


	    #  Clear error stack again, make sure all is clean before we return.
	    #
	    errclr(); eval { undef } if $@;

	};


	#  Check if render went OK, if not revert to text - better than
	#  showing nothing ..
	#
        if ($@ || !$status) {
            $WEBDYNE_ERROR_TEXT=1;
            return $self->err_html($errstr);
        }
        else {
            return $status
        }

    }

}


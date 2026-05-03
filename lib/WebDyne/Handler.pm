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
package WebDyne::Handler;


#  Compiler Pragma
#
use strict qw(vars);
use vars   qw($VERSION);
use warnings;
no warnings qw(uninitialized);


#  WebDyne Modules.
#
use WebDyne::Constant;
use WebDyne::Util;


#  Version information
#
$VERSION='2.087_619';


#  Debug
#
debug("%s loaded, version $VERSION", __PACKAGE__);


#  And done
#
1;

#------------------------------------------------------------------------------


sub import {


    #  Will only work if called from within a __PERL__ block in WebDyne
    #
    my ($class, @param)=@_;
    my $self_cr=UNIVERSAL::can(scalar caller, 'self') || return;
    my $self=$self_cr->()                             || return;
    my %param=(@param == 1) ? (handler => @param) : @param;
    $self->set_handler($param{'handler'});

}
__END__


=pod

=head1 WebDyne::Handler(3pm)

=head1 NAME

WebDyne::Handler - WebDyne handler module, forces use non-chained WebDyne handler. 

=head1 SYNOPSIS

SYNOPSIS

    #  Basic usage in a simple file in a directory which forces WebDyne::Chain usage
    #
    <start_html>
    Server local time is: <? localtime ?>
    __PERL__
    use WebDyne::Handler;

=head1 DESCRIPTION

WebDyne::Handler module forces plain (non-chained) processing of a page. This can be useful in an environment where WebDyne::Chain has been configured to process all pages in a directory via alternate configuration options (e.g. Dir_config or other settings).

Using this module will ensure there is no pre or post processing of results by any WebDyne::Chain modules. 

B<<< WARNING >>>: If you use WebDyne::Chain to load an authentication or session tracking module they will not be run on any pages that use this module, which may result in inadvertently allowing unauthenticated access to pages.

=head1 USAGE

WebDyne::Handler used as per the synopsis.

=head1 METHODS

WebDyne::Handler does not expose any public methods.

=head1 OPTIONS

WebDyne::Handler does not support any options at module import.

=head1 AUTHOR

Andrew Speer <andrew.speer@isolutions.com.au> and contributors.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself. See  L<http://dev.perl.org/licenses/|http://dev.perl.org/licenses/> .

=cut
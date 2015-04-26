#  This file is part of WebDyne.
#
#  This software is Copyright (c) 2015 by Andrew Speer <andrew@webdyne.org>.
#
#  This is free software, licensed under:
#
#    The GNU General Public License, Version 2, June 1991
#
#  Full license text is available at:
#
#  <http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt>
#
#  Load Apache::compat if running mod_perl version 1.99 - which were dev/test versions
#  of mod_perl 2.0.
#
use strict qw(vars);
use vars qw($VERSION);
$VERSION='1.240';
if (($ENV{'MOD_PERL'}=~/1\.99/) && ($ENV{'MOD_PERL_API_VERSION'} < 2)) {
  eval ("use Apache::compat");
  eval { undef } if $@;
}
1;

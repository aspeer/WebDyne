#  Load Apache::compat if running mod_perl version 1.99 - which were dev/test versions
#  of mod_perl 2.0.
#
if (($ENV{'MOD_PERL'}=~/1\.99/) && ($ENV{'MOD_PERL_API_VERSION'} < 2)) {
  eval ("use Apache::compat");
  eval { undef } if $@;
}
1;

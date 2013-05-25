#------------------------------------------------------------------------------
#
#  WebDyne Apache configuration section
#
#------------------------------------------------------------------------------
#
#


#  Need mod_perl, load up if not already done
#
<!-- 

#
my @out;
if ($MP2_INSTALLED) {
	@out=(
		'<IfModule !mod_perl.c>',
        	"LoadModule perl_module \"$FILE_MOD_PERL_LIB\"",
       		'</IfModule>'
        );
}
else {
	@out=(
		'<IfModule !mod_perl.c>',
        	"LoadModule perl_module \"$FILE_MOD_PERL_LIB\"",
       		'AddModule  mod_perl.c',
       		'</IfModule>'
       	);
}
$OUT=join($/, @out);

-->


#  Fix up @INC path, do any other init stuff before loading WebDyne
#  module
#
<!--
use Config;

my $installbin_dn=$DIR_INSTALLBIN || $Config{'installbin'};
my $perl5lib_fn;

unless ($perl5lib_fn=$INC{$FILE_PERL5LIB}) {
	$perl5lib_fn=File::Spec->catfile($installbin_dn, $FILE_PERL5LIB);
}
else {
	$perl5lib_fn=File::Spec->canonpath($perl5lib_fn);
}

$OUT=qq[PerlRequire "$perl5lib_fn"]

-->


#  Load Apache::compat module if running mod_perl 1.99
#
<!--
use Config;

my $installbin_dn=$DIR_INSTALLBIN || $Config{'installbin'};

my $mod_perl_1_99_compat_fn=File::Spec->catfile($installbin_dn, $FILE_MOD_PERL_1_99_COMPAT);
$OUT=qq[PerlRequire "$mod_perl_1_99_compat_fn"]

-->


#  Load WebDyne modules
#
PerlModule	WebDyne WebDyne::Compile


#  Associate .psp files with WebDyne
#
<!-- 
my @out;
if ($MP2_INSTALLED) {
	@out=(
		'AddHandler	perl-script	.psp',
		'PerlHandler	WebDyne'
        );
}
else {
	@out=(
		'<LocationMatch "\.psp">',
		'SetHandler perl-script',
		'PerlHandler WebDyne',
		'</LocationMatch>'
       	);
}
$OUT=join($/, @out);

-->


#  Set disk cache dir and allow apache access
#
PerlSetVar WEBDYNE_CACHE_DN "<!-- $WEBDYNE_CACHE_DN -->"
<Directory "<!-- $WEBDYNE_CACHE_DN -->">
Order allow,deny
Allow from all
Deny from none
</Directory>


#  Error display/extended display on/off. See WebDyne::Constant for granular options. Set to 1 to enable, 0 to disable
#
<Perl>
$WebDyne::WEBDYNE_ERROR_SHOW=1;
$WebDyne::WEBDYNE_ERROR_SHOW_EXTENDED=0;
</Perl>

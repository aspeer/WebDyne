#!perl


#  Load
#
use Test::More qw(no_plan);
BEGIN { use_ok( 'WebDyne' ); }
require_ok( 'WebDyne' );


#  Correct version loads
#
use FindBin qw($RealBin);
my $version_fn=File::Spec->catfile(
	$RealBin, 
	File::Spec->updir,
	qw(lib WebDyne VERSION.pm)
);
my $version=do $version_fn;
ok( $WebDyne::VERSION == $version, 'version match');


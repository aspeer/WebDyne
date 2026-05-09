#!/bin/perl
#
#  Regression test for static file dispatch through the fake request path
#
use strict qw(vars);
use warnings;

use Test::More tests => 4;
use HTTP::Status qw(HTTP_OK);
use IO::String;
use FindBin qw($RealBin);
use lib "$RealBin/../lib";

require_ok('WebDyne::Request::Fake');

my $html = q();
my $select_fh = IO::String->new($html);
my $source_fn = 'lib/WebDyne/index.css';

my $r = WebDyne::Request::Fake->new(
    filename => $source_fn,
    select   => $select_fh,
);

my $r_child = $r->lookup_file($source_fn);
isa_ok($r_child, 'WebDyne::Request::PSGI::Static');

my $status;
my $ok = eval { $status = $r_child->run(); 1 };
ok($ok, 'static file run does not die');

SKIP: {
    skip('static file run died', 1) unless $ok;
    is($status, HTTP_OK, 'static file run returns HTTP_OK');
}

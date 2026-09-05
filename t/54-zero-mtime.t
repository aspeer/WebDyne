#!/bin/perl
#
#  Files dated at the epoch must compile and load from the disk cache.
#
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_CACHE_DN'}=tempdir(CLEANUP => 1);
    $ENV{'WEBDYNE_CACHE_STAT_TTL'}=0;
    $ENV{'WEBDYNE_RELOAD'}=0;
}

use WebDyne qw(html);
use WebDyne::Template;

my $root_dn=tempdir(CLEANUP => 1);
my $page_fn=File::Spec->catfile($root_dn, 'epoch.psp');
open(my $page_fh, '>', $page_fn) || die "unable to create $page_fn: $!";
print {$page_fh} '<p>Epoch source renders</p>';
close($page_fh);
is(utime(0, 0, $page_fn), 1, 'set source timestamp to zero');
is((stat($page_fn))[9], 0, 'source timestamp is zero');
like(html($page_fn), qr/Epoch source renders/, 'compile epoch source without a disk cache');

my @cache_fn=grep { /[\/]?[0-9a-f]{32}\z/ }
    glob(File::Spec->catfile($ENV{'WEBDYNE_CACHE_DN'}, '*'));
is(scalar(@cache_fn), 1, 'compiled page is saved in the disk cache');
is(utime(0, 0, @cache_fn), 1, 'set disk cache timestamp to zero');

#  Simulate a fresh worker, then ensure the epoch cache is reused.
#
$WebDyne::Package{'_cache'}={};
{
    no warnings qw(redefine once);
    local *WebDyne::compile=sub { die 'unexpected recompile of epoch disk cache' };
    like(html($page_fn), qr/Epoch source renders/, 'fresh worker loads epoch disk cache');
    like(html($page_fn), qr/Epoch source renders/, 'repeat request reuses epoch memory cache');
}

#  Check template timestamp selection independently of template rendering.
#
{
    package EpochTemplate;
    our @ISA=qw(WebDyne::Template);
    sub r { return shift() }
    sub template { return \shift()->{'filename'} }
}
my $template_or=bless({filename => $page_fn}, 'EpochTemplate');
is(${$template_or->source_mtime(0)}, 0, 'epoch template and source retain zero timestamp');
is(${$template_or->source_mtime(10)}, 10, 'newer source wins over epoch template');

done_testing();

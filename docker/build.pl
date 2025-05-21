#!/usr/bin/env perl
use strict;
use warnings;
use Template;

# Quick and dirty to generate templates
#
my %base = (
  debian => 'debian:bookworm',
  alpine => 'alpine:latest',
  fedora => 'fedora:43',
  perl   => 'perl:latest'
);

# Iterate
#
while (my($family, $base_image)=each %base) {


  #  Hash of template vars
  #
  my %vars = (
    base_image    => $base_image,
    family        => $family,
  );

  
  # Render
  #
  my $tt = Template->new({ INCLUDE_PATH => '.', TRIM => 1 })
    or die Template->error();
  $tt->process('Dockerfile.tt', \%vars, "Dockerfile.$family")
    or die $tt->error();

  print "Generated Dockerfile.$family\n";

}

exit 0;
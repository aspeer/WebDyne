#!/bin/perl
#
#  Check version pinning for start_html shortcut resources
#
use strict qw(vars);
use warnings;
use Test::More tests=>6;


#  Skip any local config
#
BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
}


use WebDyne::HTML::Tiny;


sub style_hrefs {

    my $html=shift;
    return [ $html=~/<link\b[^>]*\bhref="([^"]+)"/g ];

}


sub script_srcs {

    my $html=shift;
    return [ $html=~/<script\b[^>]*\bsrc="([^"]+)"/g ];

}


my $html_or=WebDyne::HTML::Tiny->new();


is_deeply(
    style_hrefs($html_or->start_html({ pico=>1 })),
    ['https://cdn.jsdelivr.net/npm/@picocss/pico@latest/css/pico.min.css'],
    'bare shortcut keeps latest stylesheet'
);

is_deeply(
    style_hrefs($html_or->start_html({ pico=>'@2' })),
    ['https://cdn.jsdelivr.net/npm/@picocss/pico@2/css/pico.min.css'],
    'shortcut version replaces latest stylesheet version'
);

is_deeply(
    script_srcs($html_or->start_html({ htmx=>'@1.9.10' })),
    ['https://cdn.jsdelivr.net/npm/htmx.org@1.9.10/dist/htmx.min.js'],
    'shortcut version replaces latest script version'
);

is_deeply(
    script_srcs($html_or->start_html({ htmx_sse=>1 })),
    ['https://cdn.jsdelivr.net/npm/htmx-ext-sse@latest/sse.js'],
    'HTMX SSE extension shortcut loads its script'
);

my $alpine_html=$html_or->start_html({ alpine=>'@3' });
like($alpine_html, qr/src="https:\/\/cdn\.jsdelivr\.net\/npm\/alpinejs\@3\/dist\/cdn\.min\.js#defer"/, 'Alpine version and fragment are preserved');

is_deeply(
    style_hrefs($html_or->start_html({ pico=>1 })),
    ['https://cdn.jsdelivr.net/npm/@picocss/pico@latest/css/pico.min.css'],
    'version pinning does not mutate shortcut configuration'
);

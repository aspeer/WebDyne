#!/bin/perl
#
#  Regression tests for raw __PERL__ parsing.
#
use strict qw(vars);
use warnings;

BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_HEAD_INSERT'}=0;
}

use Test::More tests => 3;
use File::Temp qw(tempdir);
use File::Spec;
use Fcntl qw(:DEFAULT);
use IO::File;
use IO::String;
use WebDyne;
use WebDyne::Compile;
use WebDyne::Request::Fake;

my $temp_dn=tempdir(CLEANUP => 1);
my $page_fn=File::Spec->catfile($temp_dn, 'perl_raw_boundary.psp');

write_file(
    $page_fn,
    <<'END_PSP'
<start_html>
<perl handler/>

__PERL__

sub handler {
    my $text='<tag>';
    $text =~ s/</&lt;/g;
    return $text;
}
END_PSP
);

my $compile_or=WebDyne::Compile->new(filename => $page_fn);
my $container_ar=$compile_or->compile({
    srce        => $page_fn,
    no_perl     => 1,
    no_manifest => 1,
    stage0      => 1
});

ok($container_ar, 'page compiles to stage0');
like(
    ${$container_ar->[0]{'perl'}[0]},
    qr/\$text =~ s\/<\/&lt;\/g;/,
    'raw perl keeps substitution containing <'
);
like(${render($page_fn)}, qr/&lt;tag>/, 'page renders escaped tag text');


sub write_file {

    my ($fn, $data)=@_;
    my $fh=IO::File->new($fn, O_WRONLY | O_CREAT | O_TRUNC) ||
        die "unable to open $fn for writing, $!";
    print {$fh} $data;
    $fh->close() ||
        die "unable to close $fn, $!";

}


sub render {

    my $srce_fn=shift();
    my $html;
    my $html_fh=IO::String->new($html);
    my $r=WebDyne::Request::Fake->new(
        filename => $srce_fn,
        select   => $html_fh,
        noheader => 1
    );
    defined(WebDyne->handler($r)) ||
        die 'render error';
    $r->DESTROY();
    $html_fh->close();
    return \$html;

}

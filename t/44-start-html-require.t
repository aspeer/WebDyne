#!/bin/perl
#
#  Check start_html require/import metadata for normal and PAGI SSE requests.
#
use strict qw(vars);
use warnings;

BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_HEAD_INSERT'}=0;
}

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use Fcntl qw(:DEFAULT);
use IO::File;
use IO::String;

BEGIN {
    unshift @INC, 't';
    my $skip;
    eval { require PAGI::Test::Client; require WebDyne::PAGI; require Future::AsyncAwait; 1 }
        or $skip=$@ || 'PAGI modules unavailable';
    plan skip_all => "Skipping start_html require/import SSE test: $skip" if $skip;
}

use WebDyne;
use WebDyne::Compile;
use WebDyne::Request::Fake;

my $temp_dn=tempdir(CLEANUP => 1);
my $module_fn=File::Spec->catfile($temp_dn, 'StartHtmlRequireTest.pm');
my $page_fn=File::Spec->catfile($temp_dn, 'start_html_require.psp');

write_file(
    $module_fn,
    <<'END_MODULE'
package StartHtmlRequireTest;

use strict;
use warnings;

sub imported_value {
    return 'start_html import works';
}

1;
END_MODULE
);

write_file(
    $page_fn,
    <<'END_PSP'
<start_html sse require="StartHtmlRequireTest" import="imported_value">
<p>!{! StartHtmlRequireTest::imported_value() !} / !{! imported_value() !}</p>

__PERL__
use Future::AsyncAwait;
use HTTP::Status qw(HTTP_OK);

async sub sse {
    my ($self, $param_hr)=@_;
    my $sse_or=$self->r()->sse();
    await $sse_or->start(status => HTTP_OK);
    await $sse_or->send_event(
        event => 'loaded',
        data  => imported_value(),
    );
    $sse_or->close();
}
END_PSP
);

my $compile_or=WebDyne::Compile->new(filename => $page_fn);
my $container_ar=$compile_or->compile({
    srce        => $page_fn,
    no_perl     => 1,
    no_manifest => 1,
    stage5      => 1,
});
ok($container_ar, 'start_html require/import page compiles');
is($container_ar->[0]{'require'}, 'StartHtmlRequireTest', 'start_html require is stored as metadata');
is($container_ar->[0]{'import'}, 'imported_value', 'start_html import is stored as metadata');

like(
    ${render($page_fn)},
    qr/start_html import works \/ start_html import works/,
    'start_html require/import works during normal rendering'
);

my $app_cr=WebDyne::PAGI->new(root => $temp_dn)->to_app();
my $test_or=PAGI::Test::Client->new(app => $app_cr);
$test_or->sse('/start_html_require.psp', sub {
    my $sse=shift();
    is($sse->{'status'}, 200, 'SSE request succeeds with start_html require');
    my $event=$sse->receive_event();
    is($event->{'event'}, 'loaded', 'SSE handler runs after start_html require');
    is($event->{'data'}, 'start_html import works', 'SSE handler sees start_html import');
});

done_testing();

sub write_file {

    my ($fn, $data)=@_;
    my $fh=IO::File->new($fn, O_WRONLY | O_CREAT | O_TRUNC) ||
        die "unable to open $fn for write: $!";
    print {$fh} $data;
    $fh->close() || die "unable to close $fn: $!";
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
    defined(WebDyne->handler($r)) || die 'render error';
    $r->DESTROY();
    $html_fh->close();
    return \$html;
}

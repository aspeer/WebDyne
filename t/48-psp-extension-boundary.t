#!/bin/perl
#
#  Regression tests for PSP extension boundary matching.
#
use strict qw(vars);
use warnings;

BEGIN {
    $ENV{'WEBDYNE_CONF'}='.';
    $ENV{'WEBDYNE_ERROR_TEXT'}=1;
    $ENV{'WEBDYNE_HEAD_INSERT'}=0;
}

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use pagi_compat_helper qw(pagi_skip_reason);
use File::Path qw(make_path);
use File::Spec;
use File::Temp qw(tempdir);
use IO::File;


my $root_dn=tempdir(CLEANUP => 1);
my $upload_dn=File::Spec->catdir($root_dn, 'uploads');
make_path($upload_dn);

write_file(
    File::Spec->catfile($root_dn, 'page.psp'),
    '<html><? "REALPSP-" . 6*7 ?></html>'
);
write_file(
    File::Spec->catfile($upload_dn, 'report.psp.pdf'),
    '<html><? "DOUBLEEXT-" . 6*7 ?></html>'
);


SKIP: {
    eval { require WebDyne::PSGI; require Plack::Test; require HTTP::Request::Common; 1 }
        or skip "Skipping PSGI PSP extension boundary test: $@", 4;

    my $app_cr=WebDyne::PSGI->new(root => $root_dn)->to_app();
    my $test_or=Plack::Test->create($app_cr);

    my $res=$test_or->request(HTTP::Request::Common::GET('/page.psp'));
    is($res->code(), 200, 'PSGI positive control serves real PSP page');
    like($res->decoded_content() || '', qr/REALPSP-42/,
        'PSGI positive control executes real PSP page');

    $res=$test_or->request(HTTP::Request::Common::GET('/uploads/report.psp.pdf'));
    isnt($res->code(), 200, 'PSGI double-extension path is not treated as a PSP page');
    unlike($res->decoded_content() || '', qr/DOUBLEEXT-42/,
        'PSGI double-extension path does not execute embedded Perl');
}


SKIP: {
    my $pagi_skip=pagi_skip_reason(qw(PAGI::Test::Client PAGI::Request PAGI::Response PAGI::SSE PAGI::WebSocket Future::AsyncAwait));
    skip "Skipping PAGI PSP extension boundary test: $pagi_skip", 4
        if $pagi_skip;
    eval { require WebDyne::PAGI; require PAGI::Test::Client; 1 }
        or skip "Skipping PAGI PSP extension boundary test: $@", 4;

    my $app_cr=WebDyne::PAGI->new(root => $root_dn)->to_app();
    my $test_or=PAGI::Test::Client->new(app => $app_cr);

    my $res=$test_or->get('/page.psp');
    is($res->{'status'}, 200, 'PAGI positive control serves real PSP page');
    like($res->{'body'} || '', qr/REALPSP-42/,
        'PAGI positive control executes real PSP page');

    $res=$test_or->get('/uploads/report.psp.pdf');
    isnt($res->{'status'}, 200, 'PAGI double-extension path is not treated as a PSP page');
    unlike($res->{'body'} || '', qr/DOUBLEEXT-42/,
        'PAGI double-extension path does not execute embedded Perl');
}


done_testing();


sub write_file {

    my ($fn, $content)=@_;
    my ($volume, $directory)=File::Spec->splitpath($fn);
    make_path($directory) if length($directory) && !-d $directory;
    my $fh=IO::File->new($fn, O_WRONLY|O_CREAT|O_TRUNC) ||
        die "unable to write $fn, $!";
    print {$fh} $content;
    $fh->close();
    return $fn;

}

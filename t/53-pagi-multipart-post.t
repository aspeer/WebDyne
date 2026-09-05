#!/bin/perl
#
#  Verify multipart PAGI request bodies are staged for CGI::Simple.
#
use strict;
use warnings;

use Test::More;
use File::Spec;
use File::Temp qw(tempdir);
use IO::File;

BEGIN {
    unshift @INC, 't';
    require pagi_compat_helper;
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Test::Client PAGI::Request PAGI::Response Future::AsyncAwait Future::IO));
    plan skip_all => "Skipping PAGI multipart POST test: $skip" if $skip;
    plan skip_all => 'Skipping PAGI multipart POST test: PAGI::Request must support body_stream'
        unless PAGI::Request->can('body_stream');
    $ENV{'WEBDYNE_CONF'}='.';
}

use Future::AsyncAwait;
use Future::IO;
use WebDyne::PAGI;

my $root_dn=tempdir(CLEANUP => 1);
my $page_fn=File::Spec->catfile($root_dn, 'upload.psp');
ok(my $page_fh=IO::File->new($page_fn, O_WRONLY|O_CREAT|O_TRUNC), 'create upload page');
print {$page_fh} <<'EOF';
<p>
<perl handler="upload_summary">${summary}</perl>
__PERL__
sub upload_summary {
    my $self=shift();
    my $cgi_or=$self->CGI();
    my ($upload_or)=$cgi_or->uploads()->get_all('photo');
    my $summary=join('|',
        scalar($cgi_or->param('action') || ''),
        ($upload_or ? $upload_or->filename() : ''),
        ($upload_or ? $upload_or->content_type() : ''),
        ($upload_or ? $upload_or->size() : ''),
        ($upload_or ? unpack('H*', $upload_or->content()) : ''),
    );
    return {summary => \$summary};
}
</p>
EOF
$page_fh->close();

my $webdyne_app_cr=WebDyne::PAGI->new(root => $root_dn)->to_app();
ok($webdyne_app_cr, 'build PAGI app');
my $app_cr=async sub {
    my ($scope, $receive, $send)=@_;
    my $delayed_receive=async sub {
        await Future::IO->sleep(0.001);
        return await $receive->();
    };
    return await $webdyne_app_cr->($scope, $delayed_receive, $send);
};
ok(my $test_or=PAGI::Test::Client->new(app => $app_cr), 'create PAGI test client');

my $boundary='WebDynePAGIUploadBoundary';
my $jpeg="\xff\xd8\xff\xe0WebDyne JPEG\xff\xd9";
my $body=join('',
    "--$boundary\r\n",
    "Content-Disposition: form-data; name=\"action\"\r\n",
    "\r\n",
    "store\r\n",
    "--$boundary\r\n",
    "Content-Disposition: form-data; name=\"photo\"; filename=\"sample.jpg\"\r\n",
    "Content-Type: image/jpeg\r\n",
    "\r\n",
    $jpeg,
    "\r\n",
    "--$boundary--\r\n",
);
my $expected=join('|', 'store', 'sample.jpg', 'image/jpeg', length($jpeg), unpack('H*', $jpeg));

for my $attempt (1..3) {
    my $res_or=$test_or->post('/upload.psp',
        headers => {'Content-Type' => "multipart/form-data; boundary=$boundary"},
        body    => $body,
    );
    is($res_or->{'status'}, 200, "multipart POST $attempt returns HTTP 200");
    like($res_or->{'body'} || '', qr/\Q$expected\E/,
        "CGI::Simple receives field and binary upload $attempt");
}

my $oversize_body='x' x ($WebDyne::PAGI::WEBDYNE_CGI_POST_MAX + 1);
my $oversize_res_or=$test_or->post('/upload.psp',
    headers => {'Content-Type' => "multipart/form-data; boundary=$boundary"},
    body    => $oversize_body,
);
is($oversize_res_or->{'status'}, 413, 'multipart body above WEBDYNE_CGI_POST_MAX returns HTTP 413');

done_testing();

#
#  Verify URL-encoded PAGI request bodies are available to CGI::Simple.
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
    my $skip=pagi_compat_helper::pagi_skip_reason(qw(PAGI::Test::Client PAGI::Request PAGI::Response Future::AsyncAwait));
    plan skip_all => "Skipping PAGI form POST test: $skip" if $skip;
    $ENV{'WEBDYNE_CONF'}='.';
}

use WebDyne::PAGI;

my $root_dn=tempdir(CLEANUP => 1);
my $page_fn=File::Spec->catfile($root_dn, 'form.psp');
ok(my $page_fh=IO::File->new($page_fn, O_WRONLY|O_CREAT|O_TRUNC), 'create form page');
print {$page_fh} <<'EOF';
<p>
<perl handler="form_value">${value}</perl>
__PERL__
sub form_value {
    my $self=shift();
    my $value=$self->CGI()->param('action') || '';
    return {value => \$value};
}
</p>
EOF
$page_fh->close();

ok(my $app_cr=WebDyne::PAGI->new(root => $root_dn)->to_app(), 'build PAGI app');
ok(my $test_or=PAGI::Test::Client->new(app => $app_cr), 'create PAGI test client');

for my $attempt (1..3) {
    my $res_or=$test_or->post('/form.psp', form => { action => 'advance' });
    is($res_or->{'status'}, 200, "form POST $attempt returns HTTP 200");
    like($res_or->{'body'} || '', qr/advance/, "CGI::Simple receives URL-encoded POST field $attempt");
}

foreach my $content_type (
    'application/x-www-form-urlencoded; charset=UTF-8',
    'Application/X-Www-Form-Urlencoded',
    'Application/X-Www-Form-Urlencoded ; charset=UTF-8',
) {
    my $res_or=$test_or->post('/form.psp',
        headers => {'Content-Type' => $content_type},
        body => 'action=advance',
    );
    is($res_or->{'status'}, 200, "$content_type returns HTTP 200");
    like($res_or->{'body'} || '', qr/advance/, "$content_type preserves form fields");
}

done_testing();

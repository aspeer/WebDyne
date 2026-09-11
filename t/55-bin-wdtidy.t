use strict;
use warnings;

use Test::More;
use File::Temp qw(tempdir tempfile);
use FindBin qw($RealBin);
use lib "$RealBin";
use bin_helper qw(run_cmd write_file);

require './bin/wdtidy';

my ($version, $version_err, $version_rc)=run_cmd('tidy', '-v');
plan skip_all => 'HTML Tidy executable required' if $version_rc;
my %opt=(indent => 4, tidy => 'tidy');
my $tmp_dn=tempdir(CLEANUP => 1);

my $source="<start_html title=\"A > B\">\n<div>\n<p>Hello <b>world</b>!</p>\n</div>\n";
my $expected="<start_html title=\"A > B\">\n<div>\n    <p>Hello <b>world</b>!</p>\n</div>\n";
is(tidy_psp($source, \%opt), $expected, 'indents nested HTML without rewriting attributes or inline text');
is(tidy_psp($expected, \%opt), $expected, 'formatting is idempotent');
is(tidy_psp('<div><b>a</b><i>b</i></div>', \%opt), '<div><b>a</b><i>b</i></div>', 'does not introduce whitespace into compact content');

foreach my $example (
    '<perl>my $x="<div>\n<span>hi</span>\n</div>"; return $x;</perl>',
    '<? my $x = 1 < 2; return "<b>yes</b>" ?>',
    '!{! join("\n", "<p>", "<b>") !}',
    '<script type="application/perl">return "<p>\n<b>yes</b>\n</p>";</script>',
    '<api perl>return {text => "<p>\n<b>x</b>\n</p>"};</api>',
    '<json perl>return {text => "<p>\n<b>x</b>\n</p>"};</json>',
    '<htmx perl>return "<p>\n<b>x</b>\n</p>";</htmx>',
    '<div data-webdyne-perl>return "<p>\n<b>x</b>\n</p>";</div>',
    '<pre>  a\n<div>\n<b>b</b>\n</div>  </pre>',
    '<pre/>\n<div>\n<b>b</b>\n</div>  </pre>',
    '<plaintext>\n<div>\n<b>b</b>\n</div></plaintext>\n<div>\n<p>x</p>\n</div>',
    '<textarea>  a\n<div>\n<b>b</b>\n</div>  </textarea>',
    '<style>p::before { content: "<p>\n<b>\n</b>" }</style>',
    '<svg><text> a\n<tspan>b</tspan> c </text></svg>',
    '<!-- <div>\n<p>comment</p>\n</div> -->',
    '<popup_menu values="@{\n qw(red blue)\n}" labels="%{red => q(Red)}"/>',
    '<p title="unterminated <div>\n<b>x</b>\n</div>',
    '<perl>unclosed\n<div>\n<p>x</p>\n</div>'
) {
    my $protected=$example;
    $protected=~s/\\n/\n/g;
    my $input="<section>\n$protected\n</section>";
    my $output=tidy_psp($input, \%opt);
    ok(index($output, $protected)>=0, 'protected source preserved: '.substr($protected, 0, 35));
}

foreach my $marker (qw(__PERL__ __CODE__)) {
    my $tail="$marker\nsub handler {\n return '<div>\n<p>tail</p>\n</div>';\n}\n";
    like(tidy_psp($source.$tail, \%opt), qr/\Q$tail\E\z/, "$marker tail preserved byte for byte");
}
my $crlf=$source;
$crlf=~s/\n/\r\n/g;
my $crlf_expected=$expected;
$crlf_expected=~s/\n/\r\n/g;
is(tidy_psp($crlf, \%opt), $crlf_expected, 'retains CRLF');

write_file("$tmp_dn/input.psp", $source);
my ($stdout, $stderr, $rc)=run_cmd($^X, '-Ilib', 'bin/wdtidy', '--outfile', "$tmp_dn/output.psp", "$tmp_dn/input.psp");
is($rc, 0, 'outfile CLI succeeds');
is($stdout.$stderr, '', 'outfile CLI is quiet');
is(read_file("$tmp_dn/output.psp"), $expected, 'outfile contains formatted source');
($stdout, $stderr, $rc)=run_cmd($^X, 'bin/wdtidy', '--tidy', "$tmp_dn/missing", '--outfile', "$tmp_dn/output.psp", "$tmp_dn/input.psp");
ok($rc, 'missing backend fails');
is(read_file("$tmp_dn/output.psp"), $expected, 'backend failure preserves existing output');

foreach my $input ('', '0') {
    write_file("$tmp_dn/empty.psp", $input);
    ($stdout, $stderr, $rc)=run_cmd($^X, 'bin/wdtidy', "$tmp_dn/empty.psp");
    is($rc, 0, 'empty or false-value input succeeds');
    is($stdout, $input, 'empty or false-value input preserved');
}

write_file("$tmp_dn/broken-tidy", "#!/usr/bin/env perl\nprint qq(<root/>\\n);\n");
chmod(0755, "$tmp_dn/broken-tidy") || die $!;
($stdout, $stderr, $rc)=run_cmd($^X, 'bin/wdtidy', '--tidy', "$tmp_dn/broken-tidy", '--outfile', "$tmp_dn/output.psp", "$tmp_dn/input.psp");
ok($rc, 'backend dropping source markers fails');
is(read_file("$tmp_dn/output.psp"), $expected, 'marker validation failure preserves output');

#  Compare deterministic rendered fixtures, using a sibling temporary page so
#  relative includes and resources keep the same meaning.
#
local $ENV{'WEBDYNE_HEAD_INSERT'}=0;
foreach my $fn (qw(div.psp div_nested.psp perl_inline_simple.psp perl_pi.psp
    perl_inline_handler.psp perl_table.psp table_plain.psp pre.psp pre_span.psp
    popup_menu.psp start_form.psp start_html_bare.psp div_perl.psp
    div_perl_script.psp subst_multiline.psp)) {
    my $input=read_file("t/$fn");
    my ($tidy_fh, $tidy_fn)=tempfile('wdtidy-XXXXXX', DIR => 't', SUFFIX => '.psp', UNLINK => 1);
    print {$tidy_fh} tidy_psp($input, \%opt);
    close($tidy_fh) || die $!;
    my @command=($^X, '-Ilib', 'bin/wdrender', '--no-colour', '--no-tidy', '--no-lineno');
    if ($input=~/<(?:perl|\?)|application\/perl|data-webdyne-perl/) {
        my ($lint_out, $lint_err, $lint_rc)=run_cmd($^X, '-Ilib', 'bin/wdlint', $tidy_fn);
        is($lint_rc, 0, "$fn tidied Perl passes wdlint");
    }
    my ($before, $before_err, $before_rc)=run_cmd(@command, "t/$fn");
    my ($after, $after_err, $after_rc)=run_cmd(@command, $tidy_fn);
    is($before_rc, 0, "$fn original renders");
    is($after_rc, 0, "$fn tidied renders");
    is(normalize($after), normalize($before), "$fn renders equivalently");
}

done_testing();


sub read_file {

    my $fn=shift();
    open(my $input_fh, '<', $fn) || die $!;
    binmode($input_fh);
    local $/;
    return scalar(<$input_fh>);

}


sub normalize {

    my $html=shift();
    $html=~s/\s+/ /g;
    $html=~s/>\s+</></g;
    $html=~s/^\s+|\s+$//g;
    return $html;

}

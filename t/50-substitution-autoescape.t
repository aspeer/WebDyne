#!/bin/perl
#
#  Regression tests for request-derived text substitution escaping.
#
use strict qw(vars);
use warnings;

use Test::More;
use FindBin qw($RealBin);
use lib $RealBin;
use bin_helper qw(run_cmd write_file);
use File::Spec;
use File::Temp qw(tempdir);


BEGIN {
    my @missing;
    for my $m (qw(Plack::Test Plack::Request Plack::Response HTTP::Request::Common)) {
        eval "require $m; 1" or push @missing, $m;
    }
    plan skip_all => 'Skipping substitution autoescape test: missing ' . join(', ', @missing)
        if @missing;
}


my $root_dn=tempdir(CLEANUP => 1);
write_file(
    File::Spec->catfile($root_dn, 'subst.psp'),
    <<'END_PSP'
<html><body>
<p id="cgi">+{q}</p>
<p id="env">*{WEBDYNE_SUBST_AUTOESCAPE_ENV}</p>
<p id="request">^{user_agent}</p>
<p id="attr" title="+{q}">attr</p>
</body></html>
END_PSP
);


my $escaped=render_subst($root_dn, undef);
unlike($escaped, qr/"><script>alert\(1\)<\/script>/,
    'default text substitutions do not reflect raw attribute-breakout payload');
like($escaped, qr/<p id="cgi">&#34;&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;<\/p>/,
    'default +{} text substitution escapes CGI parameter');
like($escaped, qr/<p id="env">&#34;&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;<\/p>/,
    'default *{} text substitution escapes environment value');
like($escaped, qr/<p id="request">&#34;&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;<\/p>/,
    'default ^{} text substitution escapes request method value');
like($escaped, qr/<p id="attr" title="&#34;&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;">attr<\/p>/,
    'default +{} attribute substitution remains escaped by HTML::Tiny');


my $escaped_explicit=render_subst($root_dn, 1);
like($escaped_explicit, qr/<p id="cgi">&#34;&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;<\/p>/,
    'WEBDYNE_CGI_AUTOESCAPE=1 escapes +{} text substitution');
like($escaped_explicit, qr/<p id="env">&#34;&gt;&lt;script&gt;alert\(1\)&lt;\/script&gt;<\/p>/,
    'WEBDYNE_CGI_AUTOESCAPE=1 escapes *{} text substitution');


my $raw=render_subst($root_dn, 0);
like($raw, qr/<p id="cgi">"><script>alert\(1\)<\/script><\/p>/,
    'WEBDYNE_CGI_AUTOESCAPE=0 preserves legacy raw +{} text substitution');
like($raw, qr/<p id="env">"><script>alert\(1\)<\/script><\/p>/,
    'WEBDYNE_CGI_AUTOESCAPE=0 preserves legacy raw *{} text substitution');
like($raw, qr/<p id="request">"><script>alert\(1\)<\/script><\/p>/,
    'WEBDYNE_CGI_AUTOESCAPE=0 preserves legacy raw ^{} text substitution');


done_testing();


sub render_subst {

    my ($root_dn, $autoescape)=@_;
    my $code=<<'END_CODE';
use strict;
use warnings;
use Plack::Test;
use HTTP::Request::Common qw(GET);
use WebDyne::PSGI;
my $root=shift(@ARGV);
my $test=Plack::Test->create(WebDyne::PSGI->new(root => $root)->to_app());
my $res=$test->request(GET(
    '/subst.psp?q=%22%3E%3Cscript%3Ealert(1)%3C%2Fscript%3E&x=%22%3E%3Cscript%3E',
    'User-Agent' => '"><script>alert(1)</script>'
));
print $res->content();
END_CODE

    my ($stdout, $stderr, $rc);
    {
        local $ENV{'WEBDYNE_CONF'}='.';
        local $ENV{'WEBDYNE_HEAD_INSERT'}=0;
        local $ENV{'WEBDYNE_SUBST_AUTOESCAPE_ENV'}='"><script>alert(1)</script>';
        if (defined($autoescape)) {
            local $ENV{'WEBDYNE_CGI_AUTOESCAPE'}=$autoescape;
            ($stdout, $stderr, $rc)=run_cmd($^X, '-Ilib', '-e', $code, $root_dn);
        }
        else {
            local %ENV=%ENV;
            delete $ENV{'WEBDYNE_CGI_AUTOESCAPE'};
            ($stdout, $stderr, $rc)=run_cmd($^X, '-Ilib', '-e', $code, $root_dn);
        }
    }
    is($rc, 0, 'substitution render subprocess exits cleanly');
    is($stderr, '', 'substitution render subprocess writes no stderr');
    return $stdout;

}

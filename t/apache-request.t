use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require Apache2::RequestRec; 1 } ||
        plan skip_all => 'Apache2::RequestRec unavailable';

    #  Exercise adapter methods without initializing server-only dispatch.
    #
    sub WebDyne::Request::Apache::method { return 'POST' }
}
use WebDyne::Request::Apache;

my $table_or=bless([
    ['Set-Cookie', 'a=1'], ['Set-Cookie', 'b=2'],
    ['X-Test', 'first'], ['X-Test', 'second'],
], 'ApacheReviewTable');
my $request_or=bless({table => $table_or}, 'ApacheReviewRequest');
my $adapter_or=WebDyne::Request::Apache->new($request_or);
foreach my $method (qw(headers_in headers_out)) {
    my $headers_or=$adapter_or->$method();
    is_deeply([$headers_or->header('Set-Cookie')], ['a=1', 'b=2'], "$method preserves cookies");
    is_deeply([$headers_or->header('X-Test')], ['first', 'second'], "$method preserves other repeated headers");
}
is(scalar(@{$table_or}), 4, 'snapshots leave native table unchanged');

done_testing();


package ApacheReviewRequest;

sub headers_in { return shift()->{'table'} }
sub headers_out { return shift()->{'table'} }


package ApacheReviewTable;

sub do {
    my ($self, $callback_cr)=@_;
    foreach my $pair_ar (@{$self}) {
        $callback_cr->(@{$pair_ar}) || last;
    }
    return 1;
}

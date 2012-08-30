use strictures 1;
use Test::More;

use System::Introspector::Probe::Processes;

my $probe  = System::Introspector::Probe::Processes->new;
my $result = $probe->gather;

ok($result, 'got result');
my $data = $result->{processes};
ok($data, 'got process data');

ok(@$data, 'received processes');
ok(not(grep { not $_->{pid} } @$data), 'all entries have pid');
ok(not(grep { not $_->{args} } @$data), 'all entries have args');

done_testing;

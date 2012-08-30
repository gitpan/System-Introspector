use strictures 1;
use Test::More;

use System::Introspector::Probe::DiskUsage;

my $probe = System::Introspector::Probe::DiskUsage->new;

my $result = $probe->gather;
ok $result, 'received data';
my $data = $result->{disk_usage};
ok $data, 'received disk usage data';

ok scalar(@$data), 'received data';
my @fields = qw( filesystem blocks_1024 used available capacity mount_point );
for my $field (@fields) {
    ok not(grep { not defined $_->{$field} } @$data), "all have $field";
}

done_testing;

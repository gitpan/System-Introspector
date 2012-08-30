use strictures 1;
use Test::More;

use System::Introspector::Probe::Groups;

my $probe = System::Introspector::Probe::Groups->new;

my $result = $probe->gather;
ok $result, 'received data';
my $data = $result->{groups};
ok $data, 'received groups data';

ok scalar(keys %$data), 'received group data';
ok not(grep { not defined $_->{gid} } values %$data), 'all have gid';
ok not(grep { not defined $_->{name} } values %$data), 'all have name';
ok not(grep { not defined $_->{users} } values %$data), 'all have users';

done_testing;

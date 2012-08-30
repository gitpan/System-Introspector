use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::Host;

my $probe = System::Introspector::Probe::Host->new(
    hostname_file => "$FindBin::Bin/data/hostname",
);
my $data = $probe->gather;

ok length($data->{hostname}), 'found a hostname';
ok defined($data->{uname}{ $_ }), "has uname $_" for qw(
    hardware_platform
    kernel_name
    kernel_release
    kernel_version
    machine
    nodename
    operating_system
    processor
);

done_testing;

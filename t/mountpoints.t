use strictures 1;
use Test::More;

use System::Introspector::Probe::MountPoints;

my $probe = System::Introspector::Probe::MountPoints->new;
my $data  = $probe->gather;

ok $data->{fstab}, 'received fstab data';
ok $data->{mtab},  'received mtab data';

my @fields = qw(
    device_name
    dump_freq
    fs_type
    mount_point
    options
    pass_num
);

my $run_test = sub {
    my $tab = shift;
    return sub {
        for my $field (@fields) {
            my @entries = @{ $tab->{entries} };
            ok not(grep { not defined $_->{$field} } @entries),
                "all have $field";
        }
    };
};

subtest fstab => $run_test->($data->{fstab});
subtest mtab => $run_test->($data->{mtab});

done_testing;

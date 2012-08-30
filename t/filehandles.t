use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::FileHandles;

$ENV{PATH} = "$FindBin::Bin/bin:" . $ENV{PATH};

my $probe = System::Introspector::Probe::FileHandles->new;

my $data = $probe->gather;
ok($data, 'received result');

my $handles = $data->{handles};
ok($handles, 'received filehandle data');
ok(not(grep { not keys %$_ } @$handles), 'keys in all entries');

do {
    my $fail_probe = System::Introspector::Probe::FileHandles->new(
        lsof_command => 'lsoffakethisonedoesntexistatleastihopenot',
    );
    my $fail_data;
    $fail_data = $fail_probe->gather;
    ok $fail_data, 'received data';
    like $fail_data->{__error__}, qr{lsoffake}, 'correct error is set';
};

done_testing;

use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::Perls;

do {
    no warnings 'redefine';
    *System::Introspector::Probe::Perls::_find_possible_perl_configs = sub {
        map "$FindBin::Bin/data/perls/$_/lib/Config.pm", '5.10.0', '5.14.2',
    };
};

my $probe = System::Introspector::Probe::Perls->new(
    root => "$FindBin::Bin/data/perls",
);

my $result = $probe->gather;
ok $result, 'received data';

is $result->{__error__}, undef, 'no errors';
is $result->{perls}{"$FindBin::Bin/data/perls/5.10.0/lib/Config.pm"}
  ->{config}{version},
  '5.10.0',
  'version for 5.10.0';
is $result->{perls}{"$FindBin::Bin/data/perls/5.14.2/lib/Config.pm"}
  ->{config}{version},
  '5.14.2',
  'version for 5.14.2';

done_testing;

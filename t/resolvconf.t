use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::ResolvConf;

my $probe = System::Introspector::Probe::ResolvConf->new(
    resolv_conf_file => "$FindBin::Bin/data/resolv.conf",
);
my $result = $probe->gather;
ok $result, 'received data';
my $data = $result->{resolv_conf_file};
ok $data, 'received resolv.conf data';

is $data->{__error__}, undef, 'no errors';
ok $data->{file_name}, 'received file name';
ok $data->{body}, 'received file body';

like $data->{body}, qr{domain\s+foo}, 'domain specification';
like $data->{body}, qr{search\s+bar}, 'search specification';
like $data->{body}, qr{nameserver\s+baz}, 'first nameserver specification';
like $data->{body}, qr{nameserver\s+qux}, 'second nameserver specification';

done_testing;

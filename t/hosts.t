use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::Hosts;

my $probe = System::Introspector::Probe::Hosts->new(
    hosts_file => "$FindBin::Bin/data/hosts",
);

my $result = $probe->gather;
ok $result, 'received data';
my $data = $result->{hosts_file};
ok $data, 'received hosts data';

is $result->{__error__}, undef, 'no errors';
ok $data->{file_name}, 'received file name';

my $body = $data->{body};
ok $body, 'received a body';
like $body, qr{1.2.3.4\s+foo\s+bar}, 'first host';
like $body, qr{2.3.4.5\s+bar}, 'second host';
like $body, qr{some comment}, 'comment preserved';

done_testing;

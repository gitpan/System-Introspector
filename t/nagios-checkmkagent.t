use strictures 1;
use Test::More;

use System::Introspector::Probe::Nagios::CheckMkAgent;

no warnings 'redefine';
*System::Introspector::Probe::Nagios::CheckMkAgent::_get_check_mk_agent_output = sub {
    return map "$_\n",
        '<<<foo>>>',
        'bar',
        'baz',
        '<<<bar>>>',
        '<<<baz>>>',
        'qux';
};

my $probe = System::Introspector::Probe::Nagios::CheckMkAgent->new;
my $data = $probe->gather;

is_deeply $data,
    { nagios_check_mk_agent => {
        foo => [qw( bar baz )],
        bar => [],
        baz => [qw( qux )],
    } },
    'output parsing worked';

done_testing;

use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Config;

my $config = System::Introspector::Config->new(
    config_file => "$FindBin::Bin/data/test.conf",
);

is $config->sudo_user, 'root', 'sudo user';
is_deeply [$config->groups], [qw( stable unstable )], 'groups';
ok $config->has_group('stable'), 'has group';
ok !$config->has_group('none'), 'does not have group';
is_deeply [$config->hosts], [qw( foo bar baz qux quux quuux )], 'hosts';
is $config->user, 'introspect', 'user';

is_deeply $config->config_for_group('stable'), {
    introspect => {
        Foo => {},
        Bar => { sudo => 1 },
    },
}, 'multiple elements with one sudo';

is_deeply $config->config_for_group('unstable'), {
    introspect => {
        Qux => { sudo => 1 },
    },
}, 'single element with group-wide sudo';

done_testing;

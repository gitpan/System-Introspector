use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::Puppet;

my $probe = System::Introspector::Probe::Puppet->new(
    classes_file    => "$FindBin::Bin/data/puppet/classes.txt",
    resources_file  => "$FindBin::Bin/data/puppet/resources.txt",
);

my $data = $probe->gather;
is_deeply $data->{classes},
    [qw( user::foo settings user::foo user::bar )],
    'classes parsing';
is_deeply $data->{resources},
    [[user => 'foo'],
     [exec => 'ls -lha'],
     [file => '/home/foo/quux'],
     [package => 'baz'],
     [group => 'bar'],
     [__error__ => 'invalid'],
     [foo => 'bar']],
    'resources parsing';

done_testing;

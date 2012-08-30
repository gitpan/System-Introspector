use strictures 1;
use Test::More;
use File::Temp qw( tempdir );

use System::Introspector::Probe::Repositories::Git;

plan skip_all => q{Tests require a git executable}
    unless `which git`;

my $dir = tempdir(CLEANUP => 1);

no warnings 'redefine';
*System::Introspector::Probe::Repositories::Git::_open_locate_git_config_pipe = sub {
    my $output = "$dir/.git/config\n";
    open my $fh, '<', \$output;
    return $fh;
};

system("GIT_DIR=$dir/.git git init > /dev/null");

my $probe = System::Introspector::Probe::Repositories::Git->new(
    root => "$dir",
);

my $result = $probe->gather;
ok $result, 'received data';
my $data = $result->{git};
ok $data, 'received git data';
is scalar(keys %$data), 1, 'found single git repository';

my $wc = $data->{ $dir };
ok $wc, 'our temp repository exists in the data';
ok scalar(keys %{$wc->{config}||{}}), 'received config values';

done_testing;

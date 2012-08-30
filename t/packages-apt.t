use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::Packages::Apt;

my $probe = System::Introspector::Probe::Packages::Apt->new;
my $data  = $probe->gather;

ok(scalar(keys %$data), 'received packages');
ok(
    not(grep {
        not exists $_->{version}
    } values %{$data->{installed}{packages}}),
    'versions',
);

do {
    local $ENV{PATH} = join ':', "$FindBin::Bin/bin", $ENV{PATH};
    my $source_list = "$FindBin::Bin/data/apt/sources.list";
    my $source_list_dir = "$FindBin::Bin/data/apt/sources.list.d";
    my $probe = System::Introspector::Probe::Packages::Apt->new(
        apt_update => 1,
        apt_update_after => 0,
        apt_sources => $source_list,
        apt_sources_dir => $source_list_dir,
    );
    my $data = $probe->gather;
    is_deeply $data->{upgradable}, {
        actions => {
            inst => { foo => '(some foo info)' },
            remv => { baz => '(some baz info)' },
        },
    }, 'upgradable packages';
    ok $data->{update}{last}, 'has last update time';
    ok $data->{update}{run}, 'has apt run state';
    is_deeply $data->{sources}, {
        config => {
            sources_list => {
                file_name => $source_list,
                body => join "", map "$_\n",
                    "deb http://main.example.com foo",
                    "deb http://main.example.com bar",
            },
            sources_list_dir => {
                files => {
                    "other.list" => {
                        file_name => "$source_list_dir/other.list",
                        body => join "", map "$_\n",
                            "deb http://other.example.com foo",
                            "deb http://other.example.com bar",
                    },
                },
            }
        },
    }, 'sources';
};

done_testing;

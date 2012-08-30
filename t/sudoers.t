use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::Sudoers;

my $dir = "$FindBin::Bin/sudoers-data";

system("mkdir $dir");
system("mkdir $dir/bar_host");

my $start = write_file('sudoers',
    'foo bar',
    'baz qux',
    "#include $dir/foo_%h",
    "#includedir $dir/bar_%h",
);

my $foo_file = write_file('foo_host',
    'in foo',
);
my $bar_file = write_file("bar_host/baz",
    'in bar file',
);

my $probe = System::Introspector::Probe::Sudoers->new(
    sudoers_file => $start,
    hostname     => 'host',
);

ok((my $data = $probe->gather), 'received data');

my $inc = "#include $dir/foo_\%h\n#includedir $dir/bar_\%h\n";
is_deeply $data, {
    $start      => { body => "foo bar\nbaz qux\n$inc" },
    $foo_file   => { body => "in foo\n" },
    $bar_file   => { body => "in bar file\n" },
}, 'found files';

system("rm $_") for $start, $foo_file, $bar_file;
system("rmdir $dir/bar_host");
system("rmdir $dir");
done_testing;

sub write_file {
    my ($file, @lines) = @_;
    my $path = "$FindBin::Bin/sudoers-data/$file";
    open my $fh, '>', $path or die "Unable to write $path: $!\n";
    print $fh map "$_\n", @lines;
    return $path;
}

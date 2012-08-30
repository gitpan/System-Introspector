use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::LibDirs::Perl;

my $dir = "$FindBin::Bin/data/libdir/perl";

no warnings 'redefine';
*System::Introspector::Probe::LibDirs::Perl::_open_locate_libdirs_pipe = sub {
    my $output = "$dir/lib/perl5\n";
    open my $fh, '<', \$output;
    return $fh;
};

my $probe = System::Introspector::Probe::LibDirs::Perl->new(
    root => $dir,
);
my $data = $probe->gather;

my $sha = delete $data
    ->{libdirs_perl}{"$dir/lib/perl5"}{modules}{Foo}[0]{sha256_hex};
ok $sha, 'contains SHA fingerprint';

my $size = delete $data
    ->{libdirs_perl}{"$dir/lib/perl5"}{modules}{Foo}[0]{size};
ok $size, 'contains file size';

is_deeply $data, {
    libdirs_perl => {
        "$dir/lib/perl5" => {
            modules => {
                Foo => [
                    { file => "$dir/lib/perl5/Foo.pm", version => 0.001 },
                ],
            },
        },
    },
}, 'package found';

done_testing;

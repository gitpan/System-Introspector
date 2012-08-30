use strictures 1;
use Test::More;
use FindBin;

use System::Introspector::Probe::Users;

my $passwd_file = "$FindBin::Bin/test-passwd";
my $home = "$FindBin::Bin/data/home-testfoo";
my $nohome = "$FindBin::Bin/data/home-doesnotexist";

open my $passwd_fh, '>', $passwd_file
    or die "Unable to write $passwd_file: $!\n";
printf $passwd_fh "%s\n", join ':', @$_
    for [qw( testfoo x 23 42 comment ), $home, '/bin/false'],
        [qw( testbar x 24 43 comment ), $nohome, '/bin/false'];
close $passwd_fh;

local $ENV{PATH} = join ':',
    "$FindBin::Bin/bin",
    $ENV{PATH};

my $probe = System::Introspector::Probe::Users->new(
    passwd_file => $passwd_file,
);
my $data = $probe->gather;

do {
    my $user = $data->{users}{testfoo};
    ok $user, 'found first user';

    my $keys = $user->{ssh}{keys};
    ok $keys, 'found ssh keys structure';

    is_deeply $keys, {
        files => {
            'first.pub' => {
                file_name => "$home/.ssh/first.pub",
                body => "pubkey\n",
            },
        },
        authorized => {
            file_name => "$home/.ssh/authorized_keys",
            body => "keyA\nkeyB\n",
        },
    }, 'ssh key data';

    is_deeply $user->{groups}, [qw(
        testfoo_group_A
        testfoo_group_B
        testfoo_group_C
    )], 'groups list';

    my $tab = $user->{crontab};
    ok $tab, 'got crontab results';
    like $tab->{body}, qr{-u\s*testfoo}, 'crontab called with user option';
    like $tab->{body}, qr{-l}, 'crontab asked for list';
};

do {
    my $user = $data->{users}{testbar};
    ok $user, 'found second user';

    my $keys = $user->{ssh}{keys};
    ok $keys, 'found ssh keys structure';

    is_deeply $keys, {
        files => {},
        authorized => {
            file_name => "$nohome/.ssh/authorized_keys",
            body => '',
        },
    }, 'ssh key data';
};

#ok((my $user = $data->{users}{ +getlogin }), 'found own user');
#ok(defined($user->{ $_ }), "$_ is defined")
#    for qw( comment crontab gid groups home shell ssh uid username );
#ok(not(exists $user->{crontab}{error}), 'no crontab error');
#is($user->{ssh}{keys}{error}, undef, 'no ssh keys error');


unlink $passwd_file;
done_testing;

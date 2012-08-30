package System::Introspector::State;
use Moo;
use File::Tree::Snapshot;
use System::Introspector::Gatherer;
use Object::Remote::Future qw( await_all );

use JSON::Diffable qw( encode_json );

has config => (is => 'ro', required => 1);

has root => (is => 'ro', required => 1);

sub user { $_[0]->config->user }

sub sudo_user { $_[0]->config->sudo_user }

sub _log { shift; printf "[%s] %s\n", scalar(localtime), join '', @_ }

sub gather {
    my ($self, @groups) = @_;
    $self->_log('Start');
    for my $group (@groups) {
        my @waiting;
        for my $host ($self->config->hosts) {
            $self->_log("Beginning to fetch group '$group' on '$host'");
            push @waiting, [$host, $self->fetch($host, $group)];
        }
        $self->_log("Now waiting for results");
        for my $wait (@waiting) {
            my ($host, @futures) = @$wait;
            my @data = await_all @futures;
            $self->_log("Received all from group '$group' on '$host'");
            $self->_store($host, $group, +{ map %$_, @data });
        }
    }
    $self->_log('Done');
    return 1;
}

sub introspectors {
    my ($self, $group) = @_;
    return $self->config->config_for_group($group)->{introspect};
}

sub fetch {
    my ($self, $host, $group) = @_;
    my $spec = $self->introspectors($group);
    my (@sudo, @nosudo);
    push(@{ $spec->{$_}{sudo} ? \@sudo : \@nosudo}, [$_, $spec->{$_}])
        for sort keys %$spec;
    my @futures;
    if (@nosudo) {
        $self->_log("Without sudo: ", join ", ", map $_->[0], @nosudo);
        my $proxy = $self->_create_gatherer(
            host => $host,
            introspectors => [@nosudo],
        );
        push @futures, $proxy->start::gather_all;
    }
    if (@sudo) {
        $self->_log("With sudo: ", join ", ", map $_->[0], @nosudo);
        my $proxy = $self->_create_gatherer(
            sudo => 1,
            host => $host,
            introspectors => [@sudo],
        );
        push @futures, $proxy->start::gather_all;
    }
    return @futures;
}

sub storage {
    my ($self, @path) = @_;
    my $storage = File::Tree::Snapshot->new(
        allow_empty  => 0,
        storage_path => join('/', $self->root, @path),
    );
    $storage->create
        unless $storage->exists;
    return $storage;
}

sub _store {
    my ($self, $host, $group, $gathered) = @_;
    $self->_log("Storing data for group '$group' on '$host'");
    my $storage = $self->storage($host, $group);
    my $ok = eval {
        my @files;
        for my $class (sort keys %$gathered) {
            my $file = sprintf '%s.json', join '/',
                map lc, map {
                    s{([a-z0-9])([A-Z])}{${1}_${2}}g;
                    $_;
                } split m{::}, $class;
            my $fh = $storage->open('>:utf8', $file, mkpath => 1);
            my $full_path = $storage->file($file);
            $self->_log("Writing $full_path");
            print $fh encode_json($gathered->{$class});
            push @files, $full_path;
        }
        $self->_cleanup($storage, [@files]);
        $self->_log("Committing");
        $storage->commit;
    };
    unless ($ok) {
        $self->_log("Rolling back snapshot because of: ", $@ || 'unknown error');
        $storage->rollback;
        die $@;
    }
    return 1;
}

sub _cleanup {
    my ($self, $storage, $known_files) = @_;
    my %known = map { ($_ => 1) } @$known_files;
    my @files = $storage->find_files('json');
    for my $file (@files) {
        next if $known{$file};
        $self->_log("Removing $file");
        unlink($file)
            or die "Unable to remove '$file': $!\n";
    }
    return 1;
}

sub _create_gatherer {
    my ($self, %arg) = @_;
    return System::Introspector::Gatherer->new_from_spec(
        user          => $self->user,
        host          => $arg{host},
        sudo_user     => $arg{sudo} && $self->sudo_user,
        introspectors => $arg{introspectors},
    );
}

1;

=head1 NAME

System::Introspector::State - Gather system state

=head1 SYNOPSIS

    my $state = System::Introspector::State->new(
        root    => '/root/path',
        config  => $config_object,
    );

    $state->gather;

=head1 DESCRIPTION

Gathers system introspection data based on configuration and stores
it with a L<File::Tree::Snapshot> object.

=head1 ATTRIBUTES

=head2 config

A L<System::Introspector::Config>

=head2 root

Path to the storage root.

=head1 METHODS

=head2 gather

    $state->gather;

Fetches all probe data and stores it in the tree below the L</root>.

=head1 SEE ALSO

=over

=item L<System::Introspector>

=back

=head1 COPYRIGHT

Copyright (c) 2012 the L<System::Introspector>
L<AUTHOR|System::Introspector/AUTHOR>,
L<CONTRIBUTORS|System::Introspector/CONTRIBUTORS> and
L<SPONSORS|System::Introspector/SPONSORS>.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut

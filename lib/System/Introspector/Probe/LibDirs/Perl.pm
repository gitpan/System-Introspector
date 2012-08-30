package System::Introspector::Probe::LibDirs::Perl;
use Moo;
use Module::Metadata;
use Digest::SHA;

use System::Introspector::Util qw(
    handle_from_command
    transform_exceptions
);

has root => (
    is      => 'ro',
    default => sub { '/' },
);

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        my $pipe = $self->_open_locate_libdirs_pipe;
        my %libdir;
        while (defined( my $line = <$pipe> )) {
            chomp $line;
            $libdir{ $line } = transform_exceptions {
                return { modules => $self->_gather_libdir_info($line) };
            };
        }
        return { libdirs_perl => \%libdir };
    };
}

sub _gather_libdir_info {
    my ($self, $libdir) = @_;
    my %module;
    my $pipe = $self->_open_locate_pm_pipe($libdir);
    while (defined( my $line = <$pipe> )) {
        chomp $line;
        my $metadata = Module::Metadata->new_from_file($line);
        next unless $metadata->name;
        my $sha = Digest::SHA->new(256);
        $sha->addfile($line);
        my $version = $metadata->version;
        push @{ $module{ $metadata->name } //= [] }, {
            file        => $line,
            version     => (
                defined($version)
                ? sprintf('%s', $version)
                : undef
            ),
            size        => scalar(-s $line),
            sha256_hex  => $sha->hexdigest,
        };
    }
    return \%module;
}

sub _open_locate_pm_pipe {
    my ($self, $libdir) = @_;
    return handle_from_command
        sprintf q{find %s -name '*.pm'}, $libdir;
}

sub _open_locate_libdirs_pipe {
    my ($self) = @_;
    my $root = $self->root;
    $root .= '/'
        unless $root =~ m{/$};
    return handle_from_command sprintf
        q{locate --regex '^%s.*lib/perl5$'}, $root;
}

1;

__END__

=head1 NAME

System::Introspector::Probe::LibDirs::Perl - Gather perl lib directory data

=head1 DESCRIPTION

Finds locations that look like L<local::lib> or comparable Perl library
directories, and extracts module information from them.

=head1 ATTRIBUTES

=head2 root

This is the root path to be searched for library directories. Defaults
to C</>.

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

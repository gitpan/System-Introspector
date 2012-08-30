package System::Introspector::Probe::Hosts;
use Moo;

use System::Introspector::Util qw(
    output_from_file
    transform_exceptions
);

has hosts_file => (
    is      => 'ro',
    default => sub { '/etc/hosts' },
);

sub gather {
    my ($self) = @_;
    my $file = $self->hosts_file;
    return {
        hosts_file => transform_exceptions {
            return {
                file_name => $file,
                body => scalar output_from_file $file,
            };
        },
    };
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Hosts - Gather known hosts

=head1 DESCRIPTION

Reads a C<hosts> file to produce a list of known hosts

=head1 ATTRIBUTES

=head2 hosts_file

The path to the C<hosts> file that should be read. Defaults to C</etc/hosts>.

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

package System::Introspector::Probe::ResolvConf;
use Moo;

use System::Introspector::Util qw(
    output_from_file
    transform_exceptions
);

has resolv_conf_file => (
    is      => 'ro',
    default => sub { '/etc/resolv.conf' },
);

sub gather {
    my ($self) = @_;
    return {
        resolv_conf_file => transform_exceptions {
            my $file = $self->resolv_conf_file;
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

System::Introspector::Probe::ResolvConf - Gather name resolution configuration

=head1 DESCRIPTION

Reads a C<resolv.conf> file to gather information about name resolution.

=head1 ATTRIBUTES

=head2 resolv_conf_file

The path to the C<resolv.conf> file that should be read. Defaults to
C</etc/resolv.conf>.

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

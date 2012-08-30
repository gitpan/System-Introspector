package System::Introspector::Probe::Puppet;
use Moo;

use System::Introspector::Util qw(
    output_from_file
    transform_exceptions
);

has classes_file => (
    is      => 'ro',
    default => sub { '/var/lib/puppet/state/classes.txt' },
);

has resources_file => (
    is      => 'ro',
    default => sub { '/var/lib/puppet/state/resources.txt' },
);

sub gather {
    my ($self) = @_;
    return {
        classes     => $self->_gather_classes,
        resources   => $self->_gather_resources,
    };
}

sub _gather_resources {
    my ($self) = @_;
    return transform_exceptions {
        my @lines = output_from_file $self->resources_file;
        chomp @lines;
        return [ map {
            m{^(\w+)\[(.*)\]$}
                ? [$1, $2]
                : [__error__ => $_];
        } @lines ];
    };
}

sub _gather_classes {
    my ($self) = @_;
    return transform_exceptions {
        my @lines = output_from_file $self->classes_file;
        chomp @lines;
        return \@lines;
    };
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Puppet - Gather puppet agent information

=head1 DESCRIPTION

Reads the C<classes.txt> and C<resources.txt> provided by puppet.

=head1 ATTRIBUTES

=head2 classes_file

The path to the C<classes.txt> puppet file.
Defaults to C</var/lib/puppet/state/classes.txt>.

=head2 resources_file

The path to the C<resources.txt> puppet file.
Defaults to C</var/lib/puppet/state/resources.txt>.

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

package System::Introspector::Probe::FileHandles;
use Moo;

use System::Introspector::Util qw(
    lines_from_command
    transform_exceptions
);

has lsof_command => (is => 'ro', default => sub { 'lsof' });

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        my @lines = lines_from_command [$self->_lsof_command_call];
        my @handles;
        for my $line (@lines) {
            chomp $line;
            my @fields = split m{\0}, $line;
            push @handles, { map {
                m{^(.)(.*)$};
                ($1, $2);
            } @fields };
        }
        return { handles => \@handles };
    };
}

sub _lsof_command_call {
    my ($self) = @_;
    return $self->lsof_command, '-F0';
}

1;

__END__

=head1 NAME

System::Introspector::Probe::FileHandles - Gather opened filehandles

=head1 DESCRIPTION

Uses C<lsof> to build a list of open filehandles.

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

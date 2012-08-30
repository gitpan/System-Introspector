package System::Introspector::Probe::Groups;
use Moo;

use System::Introspector::Util qw(
    handle_from_file
    transform_exceptions
);

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        my %group;
        my $fh = $self->_open_group_file;
        while (defined( my $line = <$fh> )) {
            chomp $line;
            next if !(length $line);
            my ($name, undef, $gid, $users) = split m{:}, $line;
            $users = length($users)
                ? [split m{,}, $users]
                : [];
            $group{ $name } = {
                name    => $name,
                gid     => $gid,
                users   => $users,
            };
        }
        return { groups => \%group };
    };
}

sub _open_group_file {
    my ($self) = @_;
    return handle_from_file '/etc/group';
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Groups - Gather group information

=head1 DESCRIPTION

Uses C</etc/group> to gather information about groups.

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

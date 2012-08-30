package System::Introspector::Probe::DiskUsage;
use Moo;

use System::Introspector::Util qw(
    lines_from_command
    transform_exceptions
);

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        my @lines = lines_from_command ['df', '-aP'];
        shift @lines; # header
        my @rows;
        for my $line (@lines) {
            my %row;
            @row{qw(
                filesystem
                blocks_1024
                used
                available
                capacity
                mount_point
            )} = split m{\s+}, $line;
            push @rows, \%row;
        }
        no warnings 'uninitialized';
        return { disk_usage => [ sort {
            ($a->{filesystem} cmp $b->{filesystem})
            ||
            ($a->{mount_point} cmp $b->{mount_point})
        } @rows ] };
    };
}

1;

__END__

=head1 NAME

System::Introspector::Probe::DiskUsage - Gather disk space usage data

=head1 DESCRIPTION

Uses C<df> to get data about current disk usage.

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

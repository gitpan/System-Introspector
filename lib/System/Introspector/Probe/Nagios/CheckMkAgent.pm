package System::Introspector::Probe::Nagios::CheckMkAgent;
use Moo;

use System::Introspector::Util qw(
    lines_from_command
    transform_exceptions
);

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        my @lines = $self->_get_check_mk_agent_output;
        chomp @lines;
        my %plugin;
        my $current;
        for my $line (@lines) {
            if ($line =~ m{^<<<(.+)>>>$}) {
                $plugin{ $1 } = $current = [];
                next;
            }
            next unless $current;
            push @$current, $line;
        }
        return { nagios_check_mk_agent => \%plugin };
    };
}

sub _get_check_mk_agent_output {
    return lines_from_command ['check_mk_agent'];
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Nagios::CheckMkAgent - Gather check_mk_agent output

=head1 DESCRIPTION

Parses the output of C<check_mk_agent> to gather data available to Nagios.

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

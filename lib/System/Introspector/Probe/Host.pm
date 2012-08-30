package System::Introspector::Probe::Host;
use Moo;

use System::Introspector::Util qw(
    handle_from_command
    output_from_command
    output_from_file
    transform_exceptions
);

has hostname_file => (is => 'ro', default => sub {'/etc/hostname' });

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        return {
            hostname => $self->_gather_hostname,
            uname    => $self->_gather_uname_info,
        };
    };
}

my @UnameFields = qw(
    kernel_name
    kernel_release
    kernel_version
    nodename
    machine
    processor
    hardware_platform
    operating_system
);

sub _gather_uname_info {
    my ($self) = @_;
    my %uname;
    for my $field (@UnameFields) {
        (my $option = $field) =~ s{_}{-}g;
        my $value = output_from_command [uname => "--$option"];
        chomp $value;
        $uname{ $field } = $value;
    }
    return \%uname;
}

sub _gather_hostname {
    my ($self) = @_;
    my $hostname = output_from_file $self->hostname_file;
    chomp $hostname;
    $hostname =~ s{(?:^\s+|\s+$)}{}g;
    return $hostname;
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Host - Gather generic host information

=head1 DESCRIPTION

Gathers the hostname and information provided by C<uname>.

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

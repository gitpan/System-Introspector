package System::Introspector::Probe::MountPoints;
use Moo;

use System::Introspector::Util qw(
    handle_from_file
    transform_exceptions
);

sub gather {
    my ($self) = @_;
    return {
        mtab => transform_exceptions {
            return { entries
                => $self->_parse_tab_fh($self->_open_fh('/etc/mtab')) };
        },
        fstab => transform_exceptions {
            return { entries
                => $self->_parse_tab_fh($self->_open_fh('/etc/fstab')) };
        },
    };
}

sub _open_fh {
    my ($self, $file) = @_;
    return handle_from_file $file;
}

sub _parse_tab_fh {
    my ($self, $fh) = @_;
    my @mounts;
    while (defined( my $line = <$fh> )) {
        chomp $line;
        next if $line =~ m{^\s*$}
             or $line =~ m{^\s*#};
        my ($device, $point, $type, $opt, $dump, $pass)
            = split m{\s+}, $line;
        push @mounts, {
            device_name => $device,
            mount_point => $point,
            fs_type     => $type,
            dump_freq   => $dump,
            pass_num    => $pass,
            options     => {
                map {
                    my ($name, $value) = split m{=}, $_, 2;
                    $value = 1
                        unless defined $value;
                    ($name => $value);
                } split m{,}, $opt,
            },
        };
    }
    no warnings 'uninitialized';
    return [ sort {
        ($a->{device_name} cmp $b->{device_name})
        ||
        ($a->{mount_point} cmp $b->{mount_point})
    } @mounts ];
}

1;

__END__

=head1 NAME

System::Introspector::Probe::MountPoints - Gather moint point information

=head1 DESCRIPTION

Reads C<fstab> and C<mtab> files to provide mount point information.

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

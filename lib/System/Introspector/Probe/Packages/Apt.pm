package System::Introspector::Probe::Packages::Apt;
use Moo;
use File::Basename;

use System::Introspector::Util qw(
    handle_from_command
    transform_exceptions
    output_from_file
    files_from_dir
);

has apt_lists_dir => (is => 'ro', builder => 1);
has apt_update_after => (is => 'ro', default => sub { 86400 });
has apt_update => (is => 'ro');

has apt_sources => (is => 'ro', builder => 1);
has apt_sources_dir => (is => 'ro', builder => 1);

sub _build_apt_lists_dir   { '/var/lib/apt/lists' }
sub _build_apt_sources     { '/etc/apt/sources.list' }
sub _build_apt_sources_dir { '/etc/apt/sources.list.d' }

sub gather {
    my ($self) = @_;
    return {
        update => {
            last => $self->_last_apt_update,
            run => transform_exceptions {
                return { result => $self->_check_apt_state };
            },
        },
        installed => transform_exceptions {
            return { packages => $self->_gather_installed };
        },
        upgradable => transform_exceptions {
            return { actions => $self->_gather_upgradable };
        },
        sources => transform_exceptions {
            return { config => $self->_gather_sources };
        },
    };
}

sub _last_apt_update {
    my ($self) = @_;
    return scalar( (stat($self->apt_lists_dir))[9] );
}

sub _check_apt_state {
    my ($self) = @_;
    return 'disabled' unless $self->apt_update;
    my $threshold   = $self->apt_update_after;
    my $last_change = $self->_last_apt_update;
    return 'no'if ($last_change + $threshold) > time;
    handle_from_command 'apt-get update';
    return 'yes';
}

sub _open_dpkg_query_pipe {
    my ($self) = @_;
    return handle_from_command 'dpkg-query --show';
}

sub _open_apt_get_upgrade_simulation_pipe {
    my ($self) = @_;
    return handle_from_command 'apt-get -s upgrade';
}

sub _gather_sources {
    my ($self) = @_;
    my $sources_dir = $self->apt_sources_dir;
    return {
        'sources_list' => $self->_fetch_source_list($self->apt_sources),
        'sources_list_dir' => (-e $sources_dir) ? transform_exceptions {
            return +{ files => +{ map {
                ($_, $self->_fetch_source_list("$sources_dir/$_"));
            } files_from_dir $sources_dir } };
        } : {},
    };
}

sub _fetch_source_list {
    my ($self, $file) = @_;
    return transform_exceptions {
        return {
            file_name => $file,
            body => scalar(output_from_file $file),
        };
    };
}

sub _gather_upgradable {
    my ($self) = @_;
    my $pipe = $self->_open_apt_get_upgrade_simulation_pipe;
    my %action;
    while (defined( my $line = <$pipe> )) {
        chomp $line;
        if ($line =~ m{^(inst|remv)\s+(\S+)\s+(.+)$}i) {
            $action{ lc($1) }{ $2 } = $3;
        }
    }
    return \%action;
}

sub _gather_installed {
    my ($self) = @_;
    my $pipe = $self->_open_dpkg_query_pipe;
    my %package;
    while (defined( my $line = <$pipe> )) {
        chomp $line;
        my ($package, $version) = split m{\s+}, $line;
        $package{ $package } = {
            version => $version,
        };
    }
    return \%package;
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Packages::Apt - Gather APT package status

=head1 DESCRIPTION

Uses C<dpkg-query> to list all installed packages.

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

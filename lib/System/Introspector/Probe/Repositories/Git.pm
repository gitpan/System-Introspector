package System::Introspector::Probe::Repositories::Git;
use Moo;

use System::Introspector::Util qw(
    handle_from_command
    transform_exceptions
    lines_from_command
);

has root => (
    is      => 'ro',
    default => sub { '/' },
);

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        my $pipe = $self->_open_locate_git_config_pipe;
        my %location;
        while (defined( my $line = <$pipe> )) {
            chomp $line;
            next unless $line =~ m{^(.+)/\.git/config$};
            my $base = $1;
            $location{ $base } = $self->_gather_git_info($line);
        }
        return { git => \%location };
    };
}

sub _gather_git_info {
    my ($self, $config) = @_;
    return {
        config_file => $config,
        config      => transform_exceptions {
            $self->_gather_git_config($config);
        },
        tracked     => transform_exceptions {
            $self->_gather_track_info($config);
        },
    };
}

sub _gather_track_info {
    my ($self, $config) = @_;
    (my $git_dir = $config) =~ s{/config$}{};
    return $self->_find_tracking($git_dir);
}

sub _find_tracking {
    my ($self, $dir) = @_;
    local $ENV{GIT_DIR} = $dir;
    my @lines = lines_from_command
        ['git', 'for-each-ref',
            '--format', q{OK %(refname:short) %(upstream:short)},
            'refs/heads',
        ];
    my %branch;
    for my $line (@lines) {
        if ($line =~ m{^OK\s+(\S+)\s+(\S+)?$}) {
            my ($local, $remote) = ($1, $2);
            $branch{ $local } = {
                upstream => $remote,
                changed_files => transform_exceptions {
                    $self->_find_changes($dir, $local, $remote);
                },
                local_commit_count => transform_exceptions {
                    $self->_find_commit_count($dir, $local, $remote);
                },
            }
        }
        else {
            return { __error__ => join "\n", @lines };
        }
    }
    return { branches => \%branch };
}

sub _find_commit_count {
    my ($self, $dir, $local, $remote) = @_;
    return { __error__ => "No remote" }
        unless defined $remote;
    local $ENV{GIT_DIR} = $dir;
    my @lines = lines_from_command
        ['git', 'log', '--oneline', "$remote..$local"];
    return scalar @lines;
}

sub _find_changes {
    my ($self, $dir, $local, $remote) = @_;
    return { __error__ => "No remote" }
        unless defined $remote;
    local $ENV{GIT_DIR} = $dir;
    my @lines = lines_from_command
        ['git', 'diff', '--name-only', $local, $remote];
    return \@lines;
}

sub _gather_git_config {
    my ($self, $config) = @_;
    my $pipe = $self->_open_git_config_pipe($config);
    my %config;
    while (defined( my $line = <$pipe> )) {
        chomp $line;
        my ($name, $value) = split m{=}, $line, 2;
        $config{ $name } = $value;
    }
    return { contents => \%config };
}

sub _open_git_config_pipe {
    my ($self, $config) = @_;
    return handle_from_command "git config --file $config --list";
}

sub _open_locate_git_config_pipe {
    my ($self) = @_;
    (my $root = $self->root) =~ s{/$}{};
    return handle_from_command sprintf
        q{locate --regex '^%s/.*\\.git/config$'}, $root;
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Repositories::Git - Gather Git repository info

=head1 DESCRIPTION

Find Git repositories and gathers their information.

=head1 ATTRIBUTES

=head2 root

This is the root path for the search of git directories. Defaults to C</>.

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

package System::Introspector::Probe::Perls;
use Moo;

use System::Introspector::Util qw(
    transform_exceptions
    handle_from_command
    fail
);

has root => (
    is      => 'ro',
    default => sub { '/' },
);

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        my @configs = $self->_find_possible_perl_configs;
        my %found;
        my %seen;
        for my $config (@configs) {
            my $info = transform_exceptions {
                return $self->_gather_info($config);
            };
            next if $info
                and $info->{config}{sitelibexp}
                and $seen{$info->{config}{sitelibexp}}++;
            $found{$config} = $info
                if defined $info;
        }
        return { perls => \%found };
    };
}

sub _gather_info {
    my ($self, $config) = @_;
    open my $fh, '<', $config
        or fail "Unable to determine '$config': $!";
    my $first_line = <$fh>;
    return undef
        unless defined $first_line and $first_line =~ m{^#.+configpm};
    my %info;
    my $is_info;
  LINE:
    while (defined( my $line = <$fh> )) {
        if ($line =~ m{tie\s+\%Config}) {
            $is_info++;
            next LINE;
        }
        chomp $line;
        if ($line =~ m{^\s*([a-z0-9_]+)\s*=>\s*'(.*)',\s*$}i) {
            $info{$1} = $2;
        }
        elsif ($line =~ m{^\s*([a-z0-9_]+)\s*=>\s*undef,$}i) {
            $info{$1} = undef;
        }
    }
    return {
        (defined $info{scriptdir} and $info{version})
        ? (executable => join('/', $info{scriptdir}, 'perl' . $info{version}))
        : (),
        config => \%info,
    };
}

sub _find_possible_perl_configs {
    my ($self) = @_;
    (my $root = $self->root) =~ s{/$}{};
    my $handle = handle_from_command sprintf
        q{locate --regex '^%s/.*/Config.pm$'}, $root;
    my @lines = <$handle>;
    chomp @lines;
    return @lines;
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Perls - Locate perl installations

=head1 DESCRIPTION

Tries to locate perl installations on the system and collects
information about them.

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

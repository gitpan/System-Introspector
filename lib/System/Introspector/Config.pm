package System::Introspector::Config;
use Moo;
use Config::General;
use File::Basename;

has config => (is => 'lazy');

has config_file => (is => 'ro', required => 1);

sub _build_config {
    my ($self) = @_;
    my $reader = Config::General->new($self->config_file);
    my %config = $reader->getall;
    return \%config;
}

sub sudo_user { $_[0]->config->{sudo_user} }

sub groups { sort keys %{ $_[0]->config->{group} || {} } }

sub has_group { exists $_[0]->config->{group}{ $_[1] } }

my $_load_host_file = sub {
    my ($self, $path) = @_;
    my $full_path = join '/', dirname($self->config_file), $path;
    open my $fh, '<:utf8', $full_path
        or die "Unable to read host_file '$full_path': $!\n";
    my @hosts = <$fh>;
    chomp @hosts;
    return grep { m{\S} and not m{^\s*#} } @hosts;
};

sub hosts {
    my ($self) = @_;
    my $host_spec = $self->config->{host};
    my $host_file = $self->config->{host_file};
    return(
        ref($host_spec)
            ? @$host_spec
            : defined($host_spec) ? $host_spec : (),
        defined($host_file)
            ? $self->$_load_host_file($host_file)
            : (),
    );
}

sub user { $_[0]->config->{user} }

my $_get_inherited = sub {
    my $data = shift;
    $data ||= {};
    return
        map  { ($_ => $data->{$_}) }
        grep { exists $data->{$_} }
        qw( sudo );
};

sub config_for_group {
    my ($self, $name) = @_;
    my %common;
    my $config = $self->config;
    %common = (%common, $config->$_get_inherited);
    my $group = $config->{group}{ $name };
    %common = (%common, $group->$_get_inherited);
    return {
        introspect => {
            map {
                ($_ => {
                    %common,
                    %{ $group->{introspect}{ $_ } || {} },
                });
            } keys %{ $group->{introspect} || {} },
        },
    };
}

1;

=head1 NAME

System::Introspector::Config - Configuration file access

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

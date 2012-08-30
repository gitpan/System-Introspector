package System::Introspector::Gatherer;
use Moo;
use Object::Remote;
use Object::Remote::Future;
use System::Introspector::Gatherer::Bridge;
use Module::Runtime qw( use_module );

has introspectors => (is => 'ro', required => 1);

sub gather_all {
    my ($self) = @_;
    my %report;
    for my $spec (@{ $self->introspectors }) {
        my ($base, $args) = @$spec;
        $report{$base} = use_module("System::Introspector::Probe::$base")
            ->new($args)
            ->gather;
    }
    return \%report;
}

sub _new_direct {
    my ($class, $remote, $args) = @_;
    return $class->new::on($remote, $args || {});
}

sub _new_bridged {
    my ($class, $bridge, $remote, $args) = @_;
    return System::Introspector::Gatherer::Bridge->new::on($bridge,
        remote_spec  => $remote,
        remote_class => $class,
        remote_args  => $args || {},
    );
}

sub new_from_spec {
    my ($class, %arg) = @_;
    my ($user, $host, $sudo_user) = @arg{qw( user host sudo_user )};
    my $sudo = defined($sudo_user) ? sprintf('%s@', $sudo_user) : undef;
    my $args = { introspectors => $arg{introspectors} };
    if (defined $host) {
        my $remote = join '@', grep defined, $user, $host;
        if (defined $sudo_user) {
            return $class->_new_bridged($remote, $sudo, $args);
        }
        else {
            return $class->_new_direct($remote, $args);
        }
    }
    else {
        if (defined $sudo_user) {
            return $class->_new_direct($sudo, $args);
        }
        else {
            return $class->new($args);
        }
    }
}

1;

__END__

=head1 NAME

System::Introspector::Gatherer - Remote Gather Handler

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

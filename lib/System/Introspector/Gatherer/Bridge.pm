package System::Introspector::Gatherer::Bridge;
use Object::Remote;
use Object::Remote::Future;
use Moo;

has remote_spec => (is => 'ro', required => 1);
has remote_class => (is => 'ro', required => 1);
has remote_args => (is => 'ro', required => 1);
has remote => (is => 'lazy');

sub _build_remote {
    my ($self) = @_;
    return $self->remote_class
        ->new::on($self->remote_spec, $self->remote_args);
}

sub gather { (shift)->remote->gather(@_) }

1;

__END__

=head1 NAME

System::Introspector::Gatherer::Bridge - Bridged Connections

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

use strictures 1;

package System::Introspector;

our $VERSION = '0.001_001';
$VERSION = eval $VERSION;

1;

=head1 NAME

System::Introspector - framework for remote system introspection

=head1 SYNOPSIS

  $ system-introspector --storage <path> --config <path> [OPTIONS]

See L<system-introspector(1)> for detailed information about which OPTIONS
can be used.

=head1 DESCRIPTION

System::Introspector is a framework for remotely executing system wide
introspection. The introspection is done executing a set of probes
on the remote system that gather specific information. Gathered results
are stored in JSON format.

=head1 AUTHOR

 phaylon - Robert Sedlacek (cpan:PHAYLON) <r.sedlacek@shadowcat.co.uk>

=head1 CONTRIBUTORS

 mst - Matt S. Trout (cpan:MSTROUT) <mst@shadowcat.co.uk>

=head1 SPONSORS

Parts of this code were paid for by

=over

=item Socialflow L<http://www.socialflow.com>

=item Shadowcat Systems L<http://www.shadow.cat>

=back

=head1 COPYRIGHT

Copyright (c) 2012 the System::Introspector L</AUTHOR>, L</CONTRIBUTORS>
and L</SPONSORS> as listed above.

=head1 LICENSE

This library is free software and may be distributed under the same terms
as perl itself.

=cut

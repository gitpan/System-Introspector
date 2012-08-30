package System::Introspector::Probe::Sudoers;
use Moo;

use System::Introspector::Util qw(
    handle_from_command
    files_from_dir
    output_from_file
    transform_exceptions
);

has sudoers_file => (
    is      => 'ro',
    default => sub { '/etc/sudoers' },
);

has hostname => (
    is      => 'ro',
    default => sub { scalar `hostname` },
);

sub gather {
    my ($self) = @_;
    my %file = $self->_gather_files($self->sudoers_file);
    return \%file;
}

sub _gather_files {
    my ($self, $file) = @_;
    my $result = transform_exceptions {
        my @lines = output_from_file $file;
        my @result = ({ body => join '', @lines });
        for my $line (@lines) {
            chomp $line;
            if ($line =~ m{^#include\s+(.+)$}) {
                my $inc_file = $self->_insert_hostname($1);
                push @result, $self->_gather_files($inc_file);
            }
            elsif ($line =~ m{^#includedir\s+(.+)$}) {
                my $inc_dir = $self->_insert_hostname($1);
                push @result, $self->_gather_from_dir($inc_dir);
            }
        }
        return \@result;
    };
    return $file => $result
        if ref $result eq 'HASH';
    return $file => @$result;
}

sub _gather_from_dir {
    my ($self, $dir) = @_;
    my @files = files_from_dir $dir;
    my %file;
    for my $file (@files) {
        next if $file =~ m{\.} or $file =~ m{~$};
        %file = (%file, $self->_gather_files("$dir/$file"));
    }
    return %file;
}

sub _insert_hostname {
    my ($self, $value) = @_;
    my $hostname = $self->hostname;
    $value =~ s{\%h}{$hostname}g;
    return $value;
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Sudoers - Gather sudoer information

=head1 DESCRIPTION

Reads C<sudoers> files to gather information about sudo abilities. This
probe will also read all included files.

=head1 ATTRIBUTES

=head2 sudoers_file

The path to the original C<sudoers> file that should be read. Includes from this
file will be followed and provided as well.

=head2 hostname

The hostname used to resolve C<%h> hostname markers in inclusions.

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

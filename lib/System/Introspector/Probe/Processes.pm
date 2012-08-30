package System::Introspector::Probe::Processes;
use Moo;

use System::Introspector::Util qw(
    handle_from_command
    transform_exceptions
);

# args is automatically included, since it has to be last
my @Included = qw(
    blocked
    c
    class
    cputime
    egid egroup
    etime
    euid euser
    fgid fgroup
    flags
    fuid fuser
    ignored
    lwp
    nice
    nlwp
    pgid pgrp
    pid ppid
    pri
    psr
    rgid rgroup
    rss
    ruid ruser
    sgid sgroup
    sid
    size
    start_time
    stat
    suid suser
    tid
    time
    tname
    wchan
);

sub gather {
    my ($self) = @_;
    my @names = (@Included, 'args');
    return transform_exceptions {
        my $pipe = $self->_open_ps_pipe;
        my $spec = <$pipe>;
        $spec =~ s{(?:^\s+|\s+$)}{}g;
        my @fields = map lc, split m{\s+}, $spec;
        my @rows;
        while (defined( my $line = <$pipe> )) {
            chomp $line;
            $line =~ s{(?:^\s+|\s+$)}{}g;
            my @values = split m{\s+}, $line, scalar @fields;
            my %row;
            @row{ @names } = @values;
            push @rows, \%row;
        }
        return { processes => [ sort {
            ($a->{args} cmp $b->{args})
            ||
            ($a->{pid} <=> $b->{pid})
        } @rows ] };
    };
}

sub _open_ps_pipe {
    my ($self) = @_;
    return handle_from_command sprintf
        'ps -eo %s',
        join(',', @Included, 'args');
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Processes - Gather running processes

=head1 DESCRIPTION

Uses C<ps> to gather a list of all running processes.

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

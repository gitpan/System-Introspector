use strictures 1;

package System::Introspector::Util;
use Exporter 'import';
use IPC::Run qw( run );
use IPC::Open2;
use File::Spec;
use Scalar::Util qw( blessed );
use Capture::Tiny qw( capture_stderr );

our @EXPORT_OK = qw(
    handle_from_command
    handle_from_file
    output_from_command
    output_from_file
    lines_from_command
    files_from_dir
    transform_exceptions
    fail
);

do {
    package System::Introspector::_Exception;
    use Moo;
    has message => (is => 'ro');
};

sub fail { die System::Introspector::_Exception->new(message => shift) }
sub is_report_exception { ref(shift) eq 'System::Introspector::_Exception' }

sub files_from_dir {
    my ($dir) = @_;
    my $dh;
    opendir $dh, $dir
        or fail "Unable to read directory $dir: $!";
    my @files;
    while (defined( my $item = readdir $dh )) {
        next if -d "$dir/$item";
        push @files, $item;
    }
    return @files;
}

sub transform_exceptions (&) {
    my ($code) = @_;
    my $result = eval { $code->() };
    if (my $error = $@) {
        return { __error__ => $error->message }
            if is_report_exception $error;
        die $@;
    }
    return $result;
}

sub output_from_command {
    my ($command, $in) = @_;
    $in = ''
        unless defined $in;
    my ($out, $err) = ('', '');
    my $ok = eval { run($command, \$in, \$out, \$err) or die $err};
    $err = $@ unless $ok;
    return $out, $err, $ok
        if wantarray;
    $command = join ' ', @$command
        if ref $command;
    fail "Error running command ($command): $err"
        unless $ok;
    return $out;
}

sub lines_from_command {
    my ($command) = @_;
    my $output = output_from_command $command;
    chomp $output;
    return split m{\n}, $output;
}

sub handle_from_command {
    my ($command) = @_;
    my $pipe;
    local $@;
    my $ok = eval {
        my $out;
        my $child_pid;
        my @lines;
        my ($err) = capture_stderr {
          $child_pid = open2($out, File::Spec->devnull, $command);
          @lines = <$out>;
          close $out;
          waitpid $child_pid, 0;
        };
        my $content = join '', @lines;
        my $status = $? >> 8;
        $err = "Unknown error"
            unless defined $err;
        fail "Command error ($command): $err\n"
            if $status;
        open $pipe, '<', \$content;
        1;
    };
    unless ($ok) {
        my $err = $@;
        die $err
            if blessed($err) and $err->isa('System::Introspector::_Exception');
        fail "Error from command '$command': $err";
    }
    return $pipe;
}

sub handle_from_file {
    my ($file) = @_;
    open my $fh, '<', $file
        or fail "Unable to read $file: $!";
    return $fh;
}

sub output_from_file {
    my ($file) = @_;
    my $fh = handle_from_file $file;
    return <$fh>
        if wantarray;
    return do { local $/; <$fh> };
}

1;

__END__

=head1 NAME

System::Introspector::Util - Utility functions

=head1 DESCRIPTION

Contains utility functions for L<System::Introspector>.

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

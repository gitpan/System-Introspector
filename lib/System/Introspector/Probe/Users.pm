package System::Introspector::Probe::Users;
use Moo;

use System::Introspector::Util qw(
    handle_from_command
    transform_exceptions
    output_from_file
    output_from_command
    files_from_dir
    handle_from_file
);

has passwd_file => (is => 'ro', default => sub { '/etc/passwd' });

sub gather {
    my ($self) = @_;
    return transform_exceptions {
        my $fh = $self->_open_passwd_fh;
        my %user;
        while (defined( my $line = <$fh> )) {
            my $data = $self->_deparse_htpasswd_line($line);
            my $user = $data->{username};
            my $home = $data->{home};
            $data->{groups} = transform_exceptions {
                $self->_gather_user_groups($user);
            };
            $data->{ssh}{keys} = transform_exceptions {
                $self->_gather_ssh_keys($user, $home);
            };
            $data->{crontab} = transform_exceptions {
                $self->_gather_crontab($user);
            };
            $user{ $data->{username} } = $data;
        }
        return { users => \%user };
    };
}

sub _gather_crontab {
    my ($self, $user) = @_;
    my ($out, $err, $ok) = output_from_command
        ['crontab', '-u', $user, '-l'];
    unless ($ok) {
        return {}
            if $err =~ m{^no crontab}i;
        return { __error__ => $err };
    }
    return { body => $out };
}

sub _gather_ssh_keys {
    my ($self, $user, $home) = @_;
    my $ssh_dir = "$home/.ssh";
    my $ssh_authkeys = "$ssh_dir/authorized_keys";
    return {
        files => {},
        authorized => { file_name => $ssh_authkeys, body => '' }
    } unless -d $ssh_dir;
    my %key;
    for my $item (files_from_dir $ssh_dir) {
        next unless $item =~ m{\.pub$};
        $key{ $item } = transform_exceptions {
            return {
                file_name => "$ssh_dir/$item",
                body => scalar output_from_file "$ssh_dir/$item",
            };
        };
    }
    my $auth_keys = (-e $ssh_authkeys) ? (transform_exceptions {
        return {
            file_name => $ssh_authkeys,
            body => scalar output_from_file $ssh_authkeys,
        };
    }) : { file_name => $ssh_authkeys, body => '' };
    return { files => \%key, authorized => $auth_keys };
}

sub _gather_user_groups {
    my ($self, $user) = @_;
    my $groups = output_from_command [groups => $user];
    chomp $groups;
    $groups =~ s{^ .* : \s* }{}x;
    return [split m{\s+}, $groups];
}

sub _deparse_htpasswd_line {
    my ($self, $line) = @_;
    chomp $line;
    my %value;
    @value{qw( username uid gid comment home shell )}
        = (split m{:}, $line)[0, 2..6];
    return \%value;
}

sub _open_passwd_fh {
    my ($self) = @_;
    return handle_from_file $self->passwd_file;
}

1;

__END__

=head1 NAME

System::Introspector::Probe::Users - Gather user information

=head1 DESCRIPTION

Gathers information for all users in C</etc/passwd>, including cronjobs and
installed SSH public keys.

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

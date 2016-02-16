package Linux::Info::Processes;

use strict;
use warnings;
use Time::HiRes 1.9725;
use constant NUMBER => qr/^-{0,1}\d+(?:\.\d+){0,1}\z/;

=head1 NAME

Linux::Info::Processes - Collect linux process statistics.

=head1 SYNOPSIS

    use Linux::Info::Processes;

    my $lxs = Linux::Info::Processes->new;
    # or Linux::Info::Processes->new(pids => \@pids)

    $lxs->init;
    sleep 1;
    my $stat = $lxs->get;

=head1 DESCRIPTION

Linux::Info::Processes gathers process information from the virtual
F</proc> filesystem (procfs).

For more information read the documentation of the front-end module
L<Linux::Info>.

=head1 PROCESS STATISTICS

Generated by F</proc/E<lt>pidE<gt>/stat>, F</proc/E<lt>pidE<gt>/status>,
F</proc/E<lt>pidE<gt>/cmdline> and F<getpwuid()>.

Note that if F</etc/passwd> isn't readable, the key owner is set to F<N/a>.

    ppid      -  The parent process ID of the process.
    nlwp      -  The number of light weight processes that runs by this process.
    owner     -  The owner name of the process.
    pgrp      -  The group ID of the process.
    state     -  The status of the process.
    session   -  The session ID of the process.
    ttynr     -  The tty the process use.
    minflt    -  The number of minor faults the process made.
    cminflt   -  The number of minor faults the child process made.
    mayflt    -  The number of mayor faults the process made.
    cmayflt   -  The number of mayor faults the child process made.
    stime     -  The number of jiffies the process have beed scheduled in kernel mode.
    utime     -  The number of jiffies the process have beed scheduled in user mode.
    ttime     -  The number of jiffies the process have beed scheduled (user + kernel).
    cstime    -  The number of jiffies the process waited for childrens have been scheduled in kernel mode.
    cutime    -  The number of jiffies the process waited for childrens have been scheduled in user mode.
    prior     -  The priority of the process (+15).
    nice      -  The nice level of the process.
    sttime    -  The time in jiffies the process started after system boot.
    actime    -  The time in D:H:M:S (days, hours, minutes, seconds) the process is active.
    vsize     -  The size of virtual memory of the process.
    nswap     -  The size of swap space of the process.
    cnswap    -  The size of swap space of the childrens of the process.
    cpu       -  The CPU number the process was last executed on.
    wchan     -  The "channel" in which the process is waiting.
    fd        -  This is a subhash containing each file which the process has open, named by its file descriptor.
                 0 is standard input, 1 standard output, 2 standard error, etc. Because only the owner or root
                 can read /proc/<pid>/fd this hash could be empty.
    cmd       -  Command of the process.
    cmdline   -  Command line of the process.

Generated by F</proc/E<lt>pidE<gt>/statm>. All statistics provides information
about memory in pages:

    size      -  The total program size of the process.
    resident  -  Number of resident set size, this includes the text, data and stack space.
    share     -  Total size of shared pages of the process.
    trs       -  Total text size of the process.
    drs       -  Total data/stack size of the process.
    lrs       -  Total library size of the process.
    dtp       -  Total size of dirty pages of the process (unused since kernel 2.6).

It's possible to convert pages to bytes or kilobytes. Example - if the pagesize of your
system is 4kb:

    $Linux::Info::Processes::PAGES_TO_BYTES =    0; # pages (default)
    $Linux::Info::Processes::PAGES_TO_BYTES =    4; # convert to kilobytes
    $Linux::Info::Processes::PAGES_TO_BYTES = 4096; # convert to bytes

    # or with
    Linux::Info::Processes->new(pages_to_bytes => 4096);

Generated by F</proc/E<lt>pidE<gt>/io>.

    rchar                 -  Bytes read from storage (might have been from pagecache).
    wchar                 -  Bytes written.
    syscr                 -  Number of read syscalls.
    syscw                 -  Numner of write syscalls.
    read_bytes            -  Bytes really fetched from storage layer.
    write_bytes           -  Bytes sent to the storage layer.
    cancelled_write_bytes -  Refer to docs.

See Documentation/filesystems/proc.txt for more (from kernel 2.6.20)

=head1 METHODS

=head2 new()

Call C<new()> to create a new object.

    my $lxs = Linux::Info::Processes->new;

It's possible to handoff an array reference with a PID list.

    my $lxs = Linux::Info::Processes->new(pids => [ 1, 2, 3 ]);

It's also possible to set the path to the proc filesystem.

     Linux::Info::Processes->new(
        files => {
            # This is the default
            path    => '/proc',
            uptime  => 'uptime',
            stat    => 'stat',
            statm   => 'statm',
            status  => 'status',
            cmdline => 'cmdline',
            wchan   => 'wchan',
            fd      => 'fd',
            io      => 'io',
        }
    );

=head2 init()

Call C<init()> to initialize the statistics.

    $lxs->init;

=head2 get()

Call C<get()> to get the statistics. C<get()> returns the statistics as a hash reference.

    my $stat = $lxs->get;

Note:

Processes that were created between the call of init() and get() are returned as well,
but the keys minflt, cminflt, mayflt, cmayflt, utime, stime, cutime, and cstime are set
to the value 0.00 because there are no inititial values to calculate the deltas.

=head2 raw()

Get raw values.

=head1 EXPORTS

Nothing.

=head1 SEE ALSO

=over

=item *

B<proc(5)>

=item *

B<perldoc -f getpwuid>

=item *

L<Linux::Info>

=back

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 of Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

This file is part of Linux Info project.

Linux-Info is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Linux-Info is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with Linux Info.  If not, see <http://www.gnu.org/licenses/>.

=cut

our $PAGES_TO_BYTES = 0;

sub new {
    my $class = shift;
    my $opts = ref( $_[0] ) ? shift : {@_};

    my %self = (
        files => {
            path    => '/proc',
            uptime  => 'uptime',
            stat    => 'stat',
            statm   => 'statm',
            status  => 'status',
            cmdline => 'cmdline',
            wchan   => 'wchan',
            fd      => 'fd',
            io      => 'io',
        },
    );

    if ( defined $opts->{pids} ) {
        if ( ref( $opts->{pids} ) ne 'ARRAY' ) {
            die "the PIDs must be passed as a array reference to new()";
        }

        foreach my $pid ( @{ $opts->{pids} } ) {
            if ( $pid !~ /^\d+\z/ ) {
                die "PID '$pid' is not a number";
            }
        }

        $self{pids} = $opts->{pids};
    }

    foreach my $file ( keys %{ $opts->{files} } ) {
        $self{files}{$file} = $opts->{files}->{$file};
    }

    if ( $opts->{pages_to_bytes} ) {
        $self{pages_to_bytes} = $opts->{pages_to_bytes};
    }

    return bless \%self, $class;
}

sub init {
    my $self = shift;
    $self->{init} = $self->_init;
}

sub get {
    my $self = shift;

    if ( !exists $self->{init} ) {
        die "there are no initial statistics defined";
    }

    $self->{stats} = $self->_load;
    $self->_deltas;
    return $self->{stats};
}

sub raw {
    my $self = shift;
    my $stat = $self->_load;

    return $stat;
}

#
# private stuff
#

sub _init {
    my $self  = shift;
    my $file  = $self->{files};
    my $pids  = $self->_get_pids;
    my $stats = {};

    $stats->{time} = Time::HiRes::gettimeofday();

    foreach my $pid (@$pids) {
        my $stat = $self->_get_stat($pid);

        if ( defined $stat ) {
            foreach my $key (
                qw/minflt cminflt mayflt cmayflt utime stime cutime cstime sttime/
              )
            {
                $stats->{$pid}->{$key} = $stat->{$key};
            }
            $stats->{$pid}->{io} = $self->_get_io($pid);
        }
    }

    return $stats;
}

sub _load {
    my $self   = shift;
    my $file   = $self->{files};
    my $uptime = $self->_uptime;
    my $pids   = $self->_get_pids;
    my $stats  = {};

    $stats->{time} = Time::HiRes::gettimeofday();

  PID: foreach my $pid (@$pids) {
        foreach my $key (qw/statm stat io owner cmdline wchan fd/) {
            my $method = "_get_$key";
            my $data   = $self->$method($pid);

            if ( !defined $data ) {
                delete $stats->{$pid};
                next PID;
            }

            if ( $key eq "statm" || $key eq "stat" ) {
                for my $x ( keys %$data ) {
                    $stats->{$pid}->{$x} = $data->{$x};
                }
            }
            else {
                $stats->{$pid}->{$key} = $data;
            }
        }
    }

    return $stats;
}

sub _deltas {
    my $self   = shift;
    my $istat  = $self->{init};
    my $lstat  = $self->{stats};
    my $uptime = $self->_uptime;

    if ( !defined $istat->{time} || !defined $lstat->{time} ) {
        die "not defined key found 'time'";
    }

    if ( $istat->{time} !~ NUMBER || $lstat->{time} !~ NUMBER ) {
        die "invalid value for key 'time'";
    }

    my $time = $lstat->{time} - $istat->{time};
    $istat->{time} = $lstat->{time};
    delete $lstat->{time};

    for my $pid ( keys %{$lstat} ) {
        my $ipid = $istat->{$pid};
        my $lpid = $lstat->{$pid};

    # yeah, what happends if the start time is different... it seems that a new
    # process with the same process-id were created... for this reason I have to
    # check if the start time is equal!
        if ( $ipid && $ipid->{sttime} == $lpid->{sttime} ) {
            for my $k (
                qw(minflt cminflt mayflt cmayflt utime stime cutime cstime))
            {
                if ( !defined $ipid->{$k} ) {
                    die "not defined key found '$k'";
                }
                if ( $ipid->{$k} !~ NUMBER || $lpid->{$k} !~ NUMBER ) {
                    die "invalid value for key '$k'";
                }

                $lpid->{$k} -= $ipid->{$k};
                $ipid->{$k} += $lpid->{$k};

                if ( $lpid->{$k} > 0 && $time > 0 ) {
                    $lpid->{$k} = sprintf( '%.2f', $lpid->{$k} / $time );
                }
                else {
                    $lpid->{$k} = sprintf( '%.2f', $lpid->{$k} );
                }
            }

            $lpid->{ttime} = sprintf( '%.2f', $lpid->{stime} + $lpid->{utime} );

            for my $k (
                qw(rchar wchar syscr syscw read_bytes write_bytes cancelled_write_bytes)
              )
            {
                if ( defined $ipid->{io}->{$k} && defined $lpid->{io}->{$k} ) {
                    if (   $ipid->{io}->{$k} !~ NUMBER
                        || $lpid->{io}->{$k} !~ NUMBER )
                    {
                        die "invalid value for io key '$k'";
                    }
                    $lpid->{io}->{$k} -= $ipid->{io}->{$k};
                    $ipid->{io}->{$k} += $lpid->{io}->{$k};
                    if ( $lpid->{io}->{$k} > 0 && $time > 0 ) {
                        $lpid->{io}->{$k} =
                          sprintf( '%.2f', $lpid->{io}->{$k} / $time );
                    }
                    else {
                        $lpid->{io}->{$k} =
                          sprintf( '%.2f', $lpid->{io}->{$k} );
                    }
                }
            }
        }
        else {
            # calculate the statistics since process creation
            for my $k (
                qw(minflt cminflt mayflt cmayflt utime stime cutime cstime))
            {
                my $p_uptime = $uptime - $lpid->{sttime} / 100;
                $istat->{$pid}->{$k} = $lpid->{$k};

                if ( $p_uptime > 0 ) {
                    $lpid->{$k} = sprintf( '%.2f', $lpid->{$k} / $p_uptime );
                }
                else {
                    $lpid->{$k} = sprintf( '%.2f', $lpid->{$k} );
                }
            }

            for my $k (
                qw(rchar wchar syscr syscw read_bytes write_bytes cancelled_write_bytes)
              )
            {
                my $p_uptime = $uptime - $lpid->{sttime} / 100;
                $lpid->{io}->{$k} ||= 0;
                $istat->{$pid}->{io}->{$k} = $lpid->{io}->{$k};

                if ( $p_uptime > 0 ) {
                    $lpid->{io}->{$k} =
                      sprintf( '%.2f', $lpid->{io}->{$k} / $p_uptime );
                }
                else {
                    $lpid->{io}->{$k} = sprintf( '%.2f', $lpid->{io}->{$k} );
                }
            }

            $lpid->{ttime} = sprintf( '%.2f', $lpid->{stime} + $lpid->{utime} );
            $istat->{$pid}->{sttime} = $lpid->{sttime};
        }
    }
}

sub _get_statm {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat = ();

    open my $fh, '<', "$file->{path}/$pid/$file->{statm}"
      or return undef;

    my @line = split /\s+/, <$fh>;

    if ( @line < 7 ) {
        return undef;
    }

    my $ptb = $self->{pages_to_bytes} || $PAGES_TO_BYTES;

    if ($ptb) {
        @stat{qw(size resident share trs lrs drs dtp)} =
          map { $_ * $ptb } @line;
    }
    else {
        @stat{qw(size resident share trs lrs drs dtp)} = @line;
    }

    close($fh);
    return \%stat;
}

sub _get_stat {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat = ();

    open my $fh, '<', "$file->{path}/$pid/$file->{stat}"
      or return undef;

    my @line = split /\s+/, <$fh>;

    if ( @line < 38 ) {
        return undef;
    }

    @stat{
        qw(
          cmd     state   ppid    pgrp    session ttynr   minflt
          cminflt mayflt  cmayflt utime   stime   cutime  cstime
          prior   nice    nlwp    sttime  vsize   nswap   cnswap
          cpu
          )
    } = @line[ 1 .. 6, 9 .. 19, 21 .. 22, 35 .. 36, 38 ];

    my $uptime = $self->_uptime;
    my ( $d, $h, $m, $s ) =
      $self->_calsec( sprintf( '%li', $uptime - $stat{sttime} / 100 ) );
    $stat{actime} = "$d:" . sprintf( '%02d:%02d:%02d', $h, $m, $s );

    close($fh);
    return \%stat;
}

sub _get_owner {
    my ( $self, $pid ) = @_;
    my $file  = $self->{files};
    my $owner = "N/a";

    open my $fh, '<', "$file->{path}/$pid/$file->{status}"
      or return undef;

    while ( my $line = <$fh> ) {
        if ( $line =~ /^Uid:(?:\s+|\t+)(\d+)/ ) {
            $owner = getpwuid($1) || "N/a";
            last;
        }
    }

    close($fh);
    return $owner;
}

sub _get_cmdline {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};

    open my $fh, '<', "$file->{path}/$pid/$file->{cmdline}"
      or return undef;

    my $cmdline = <$fh>;
    close $fh;

    if ( !defined $cmdline ) {
        $cmdline = "N/a";
    }

    $cmdline =~ s/\0/ /g;
    $cmdline =~ s/^\s+//;
    $cmdline =~ s/\s+$//;
    chomp $cmdline;
    return $cmdline;
}

sub _get_wchan {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};

    open my $fh, '<', "$file->{path}/$pid/$file->{wchan}"
      or return undef;

    my $wchan = <$fh>;
    close $fh;

    if ( !defined $wchan ) {
        $wchan = defined;
    }

    chomp $wchan;
    return $wchan;
}

sub _get_io {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat = ();

    if ( open my $fh, '<', "$file->{path}/$pid/$file->{io}" ) {
        while ( my $line = <$fh> ) {
            if ( $line =~ /^([a-z_]+):\s+(\d+)/ ) {
                $stat{$1} = $2;
            }
        }

        close($fh);
    }

    return \%stat;
}

sub _get_fd {
    my ( $self, $pid ) = @_;
    my $file = $self->{files};
    my %stat = ();

    if ( opendir my $dh, "$file->{path}/$pid/$file->{fd}" ) {
        foreach my $link ( grep !/^\.+\z/, readdir($dh) ) {
            if ( my $target = readlink("$file->{path}/$pid/$file->{fd}/$link") )
            {
                $stat{$pid}{fd}{$link} = $target;
            }
        }
    }

    return \%stat;
}

sub _get_pids {
    my $self = shift;
    my $file = $self->{files};

    if ( $self->{pids} ) {
        return $self->{pids};
    }

    opendir my $dh, $file->{path}
      or die "unable to open directory $file->{path} ($!)";
    my @pids = grep /^\d+\z/, readdir $dh;
    closedir $dh;
    return \@pids;
}

sub _uptime {
    my $self = shift;
    my $file = $self->{files};

    my $filename =
      $file->{path} ? "$file->{path}/$file->{uptime}" : $file->{uptime};
    open my $fh, '<', $filename or die "unable to open $filename ($!)";
    my ( $up, $idle ) = split /\s+/, <$fh>;
    close($fh);
    return $up;
}

sub _calsec {
    my $self = shift;
    my ( $s, $m, $h, $d ) = ( shift, 0, 0, 0 );
    $s >= 86400 and $d = sprintf( '%i', $s / 86400 ) and $s = $s % 86400;
    $s >= 3600  and $h = sprintf( '%i', $s / 3600 )  and $s = $s % 3600;
    $s >= 60    and $m = sprintf( '%i', $s / 60 )    and $s = $s % 60;
    return ( $d, $h, $m, $s );
}

1;

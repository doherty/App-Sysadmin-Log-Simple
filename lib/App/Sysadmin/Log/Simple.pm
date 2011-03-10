package App::Sysadmin::Log::Simple;
# ABSTRACT: application class for managing a simple sysadmin log
# VERSION
use perl5i::2;
use File::Path 2.00 qw(make_path);

=head1 SYNOPSIS

    require App::Sysadmin::Log::Simple;
    App::Sysadmin::Log::Simple->new(logdir => '/var/log/sysadmin')->run();

=head1 DESCRIPTION

C<App::Sysadmin::Log::Simple> provides an easy way to maintain a simple
single-host system administration log.

The log is single-host in the sense that it does not log anything about
the host. While you can obviously state what host you're talking about
in your log entry, there is nothing done automatically to differentiate
such log entries, and there is no built-in way to log from one host to
another.

The logs themselves are also simple - you get a single line of plain
text to say what you have to say. That line gets logged in a fashion
that is easy to read with this script, with cat, or it can be parsed
with L<Text::Markdown> (or L<Text::MultiMarkdown>, which is a more
modern drop-in replacement) and served on the web.

If you need more than a single line of text, you may wish to use that
line to point to a pastebin - you can easily create and retrieve them
from the command line with L<App::Pastebin::sprunge>.

There is also no way to audit that the logs are correct. It can be
incorrect in a number of ways:

=over 4

=item * SUDO_USER or USER can be spoofed

=item * The files can be edited at any time, they are chmod 644 and
owned by an unprivileged user

=item * The timestamp depends on the system clock

=item * ...etc

=back

Nonetheless, this is a simple, easy, and B<fast> way to get a useful
script for managing a simple sysadmin log. We believe the 80/20 rule
applies: You can get 80% of the functionality with only 20% of a
"real" solution. In the future, each log entry might be committed to
a git repository for additional tracking.

=head1 METHODS

=head2 new

Obviously, the constructor returns an C<App::Sysadmin::Log::Simple>
object. It takes a hash of options which specify:

=over 4

=item * B<mode>

Mode is one of 'log' (the default), 'view', or 'generate-index'; this
specifies what mode to run App::Sysadmin::Log::Simple in:

=over 4

=item log - add to a log file

=item view - view a log file

=item generate-index - re-build the index page

=back

=item * B<logdir>

The directory where to find the sysadmin log.

=item * B<user>

The user who owns the sysadmin log. Should be unprivileged,
but could be anything.

=item * B<preamble>

The text to prepend to the index page. Can be anything - by
default, it is a short explanation of the rationale for using
this system of logging, which probably won't make sense
for your context.

=item * date (optional)

The date to use instead of today.

=item * udp

A hashref of data regarding UDP usage. If you don't want to
send a UDP datagram, omit this. Otherwise, it has the following
structure:

    my %udp_data = ( irc => 1, port => 9002, host => 'localhost' );

=over 4

=item irc - whether to insert IRC colour codes

=item port - what port to send to

=item host - what hostname to send to

=back

=item * index_preamble

=item * view_preamble

These are both strings which are prepended to the index page (ie. above
the actual index), or the log being viewed (ie. at the top of the log
file).

=item * read_from

A filehandle reference to read from to get the log data. Defaults to STDIN.

=back

=cut

method new($class: %opts) {
    my $datetimeobj = localtime;
    if ($opts{date}) {
        my ($in_year, $in_month, $in_day) = split(/\//, $opts{date});
        my $in_date = DateTime->new(
            year  => $in_year,
            month => $in_month,
            day   => $in_day,
        ) or croak "Couldn't understand your date - use YYYY/MM/DD\n";
        croak "Cannot use a date in the future\n" if $in_date > $datetimeobj;
        $datetimeobj = $in_date;
    }
    my $self = {
        date    => $datetimeobj,
        logdir  => $opts{logdir} || '/var/log/sysadmin',
        user    => $opts{user},
        udp     => $opts{udp},
        index_preamble => $opts{index_preamble},
        view_preamble  => $opts{view_preamble},
        in             => $opts{read_from} || \*STDIN,
    };
    bless $self, $class;
}

=head2 run

This runs the application with the options specified in a hash:

=over 4

=item * view (optional)

Whether to view the log instead of add to it

=back

=cut

method run($mode) {
    make_path $self->{logdir} unless -d $self->{logdir};

    given ($mode) {
        when ('refresh-index') {
            say 'Refreshing index...';
            $self->_generate_index() and say 'Done.';
        }
        when ('view') { $self->_view_log();   }
        when ('log')  { $self->_add_to_log(); }
        default       { $self->_add_to_log(); }
    }
}

method _generate_index() {
    require File::Find::Rule;

    open my $indexfh, '>', "$self->{logdir}/index.log"; # clobbers the file
    say $indexfh $self->{index_preamble} if defined $self->{index_preamble};

    # Find relevant log files
    my @files = File::Find::Rule->mindepth(3)->in($self->{logdir});
    my @dates;
    foreach (@files) {
        if (m!(\d{4}/\d{1,2}/\d{1,2})!) { # Extract the date
            my $date = $1;
            my ($year, $month, $day) = split /\//, $date;
            push @dates, [$year, $month, $day];
        }
        else {
            warn "WTF: $_";
        }
    }
    # Sort by year, then by month, then by day
    @dates = sort { ($b->[0]*10000 + $b->[1]*100 + $b->[2]) <=> ($a->[0]*10000 + $a->[1]*100 + $a->[2]) } @dates;
    
    # Keep track of 
    my $lastyear  = 0;
    my $lastmonth = 0;
    for my $date (@dates) {
        my $year  = $date->[0];
        my $month = $date->[1];
        my $day   = $date->[2];

        if ($year != $lastyear) {
            say $indexfh "\n$year";
            say $indexfh "-" x length($year);
            $lastyear  = $year;
            $lastmonth = 0;
        }
        if ($month != $lastmonth) {
            say $indexfh "\n### $month ###\n";
            $lastmonth = $month;
        }
        if ($year == $lastyear and $month == $lastmonth) {
            say $indexfh "[$day]($year/$month/$day)"
        }
    }
    return 1;
}

method _add_to_log() {
    my $year  = $self->{date}->year;
    my $month = $self->{date}->month;
    my $day   = $self->{date}->day;

    make_path "$self->{logdir}/$year/$month" unless -d "$self->{logdir}/$year/$month";
    my $logfile = "$self->{logdir}/$year/$month/$day.log";

    # Grab the entry and log it
    say 'Log entry:';
    my $in = $self->{in};
    my $logentry = <$in>;
    # Start a new log file if one doesn't exist already
    unless (-e $logfile) {
        open my $logfh, '>>', $logfile;
        my $line = $self->{date}->day_name . ' ' . $self->{date}->month_name . " $day, $year";
        say $logfh $line;
        say $logfh "=" x length($line), "\n";
        close $logfh; # Explicitly close before calling generate_index() so the file is found
        $self->_generate_index();
    }

    open my $logfh, '>>', $logfile;
    my $timestamp = $self->{date}->hms;
    my $user = $ENV{SUDO_USER} || $ENV{USER}; # We need to know who wrote this
    print $logfh "    $timestamp $user:\t$logentry";

    $self->_to_udp($user, $logentry) if $self->{udp};

    # This might be run as root, so fix up ownership and
    # permissions so mortals can log to files root started
    my ($login, $pass, $uid, $gid) = getpwnam($self->{user});
    chown $uid, $gid, $logfile;
    chmod 0644, $logfile;
}

method _to_udp($user, $logentry) {
    require IO::Socket;
    my $sock = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => ($self->{udp}->{host} || 'localhost'),
        PeerPort    => $self->{udp}->{port},
    );

    if ($self->{udp}->{irc}) {
        my %irc = (
            normal      => "\x0F",
            bold        => "\x02",
            underline   => "\x1F",
            white       => "\x0300",
            black       => "\x0301",
            blue        => "\x0302",
            green       => "\x0303",
            lightred    => "\x0304",
            red         => "\x0305",
            purple      => "\x0306",
            orange      => "\x0307",
            yellow      => "\x0308",
            lightgreen  => "\x0309",
            cyan        => "\x0310",
            lightcyan   => "\x0311",
            lightblue   => "\x0312",
            lightpurple => "\x0313",
            grey        => "\x0314",
            lightgrey   => "\x0315",
        );

        my $ircline = $irc{bold} . $irc{green} . '(LOG)' . $irc{normal} . ' '
            . $irc{underline} . $irc{lightblue} . $user . $irc{normal} . ': '
            . $logentry;
        send($sock, $ircline, 0);
    }
    else {
        send($sock, "(LOG) $user: $logentry", 0);
    }
    $sock->close;
}

method _view_log() {
    require IO::Pager;
    my $year  = $self->{date}->year;
    my $month = $self->{date}->month;
    my $day   = $self->{date}->day;

    my $logfh;
    try {
        open $logfh, '<', "$self->{logdir}/$year/$month/$day.log";
    }
    catch {
        die "No log for $year/$month/$day\n" unless -e "$self->{logdir}/$year/$month/$day";
    };
    local $STDOUT = IO::Pager->new(*STDOUT);
    say $self->{view_preamble} if defined $self->{view_preamble};
    while (<$logfh>) {
        print;
    }
}

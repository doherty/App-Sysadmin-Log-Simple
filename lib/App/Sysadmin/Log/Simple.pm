package App::Sysadmin::Log::Simple;
# ABSTRACT: application class for managing a simple sysadmin log

use perl5i::2;
use File::Path 2.00 qw(make_path);


=head1 SYNOPSIS

    require App::Sysadmin::Log::Simple;
    App::Sysadmin::Log::Simple->new(logdir => '/tmp/my/logdir')->run({});

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
"real" solution.

=head1 METHODS

=head2 new

Obviously, the constructor returns an C<App::Sysadmin::Log::Simple>
object. It takes a hash of options which specify:

=over 4

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
        date     => $datetimeobj,
        logdir   => $opts{logdir},
        user     => $opts{user},
        index_preamble => $opts{index_preamble},
        view_preamble  => $opts{view_preamble},
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

method run(%opts) {
    make_path $self->{logdir} unless -d $self->{logdir};

    if ($opts{view}) {
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
    elsif ($opts{'refresh-index'}) {
        say 'Refreshing index...';
        $self->_generate_index();
        say 'Done.';
    }
    else { # Add a new log entry
        my $year  = $self->{date}->year;
        my $month = $self->{date}->month;
        my $day   = $self->{date}->day;

        make_path "$self->{logdir}/$year/$month" unless -d "$self->{logdir}/$year/$month";
        my $logfile = "$self->{logdir}/$year/$month/$day.log";

        # Grab the entry and log it
        say 'Log entry:';
        my $logentry = <STDIN>;
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
        print $logfh  "$timestamp $user:\t$logentry";

        # This might be run as root, so fix up ownership and
        # permissions so mortals can log to files root started
        my ($login, $pass, $uid, $gid) = getpwnam($self->{user});
        chown $uid, $gid, $logfile;
        chmod 0644, $logfile;
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
}

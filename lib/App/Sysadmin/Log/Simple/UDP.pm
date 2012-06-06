package App::Sysadmin::Log::Simple::UDP;
use strict;
use warnings;
use Carp;
use IO::Socket::INET;
use autodie qw(:socket);

# ABSTRACT: a UDP-logger for App::Sysadmin::Log::Simple
# VERSION

=head1 DESCRIPTION

This provides a log method that sends text over a UDP socket, optionally
with IRC colour codes applied. This can be used to centralize logging on
a single machine, or echo log entries to an IRC channel.

=head1 METHODS

=head2 new

This creates a new App::Sysadmin::Log::Simple::UDP object. It takes a hash
of options:

=head3 udp

A hashref containing keys:

=over 4

=item host - default: localhost

=item port - default: 9002

=back

=head3 user

The user to attribute the log entry to

=head3 irc

Whether to apply IRC colour codes or not.

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    my $app   = $opts{app};

    $app->{udp}->{host} ||= 'localhost';
    $app->{udp}->{port} ||= 9002;

    return bless {
        do_udp  => $app->{do_udp},
        udp     => $app->{udp},
        user    => $app->{user},
    }, $class;
}

=head2 log

This creates a socket, and sends the log entry out, optionally applying IRC
colour codes to it.

=cut

sub log {
    my $self     = shift;
    my $logentry = shift;

    return unless $self->{do_udp};

    my $sock = IO::Socket::INET->new(
        Proto       => 'udp',
        PeerAddr    => $self->{udp}->{host},
        PeerPort    => $self->{udp}->{port},
    );
    carp "Couldn't get a socket: $!" unless $sock;

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

        my $ircline = $irc{bold} . $irc{green} . '(LOG)' . $irc{normal}
            . ' ' . $irc{underline} . $irc{lightblue} . $self->{user} . $irc{normal}
            . ': ' . $logentry . "\r\n";
        print $sock $ircline;
    }
    else {
        print $sock "(LOG) $self->{user}: $logentry\r\n";
    }
    $sock->shutdown(2);

    return "Logged to $self->{udp}->{host}:$self->{udp}->{port}";
}

1;

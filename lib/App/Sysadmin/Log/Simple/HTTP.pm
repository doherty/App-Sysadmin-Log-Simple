package App::Sysadmin::Log::Simple::HTTP;
use strict;
use warnings;
# ABSTRACT: a HTTP (maybe RESTful?) logger for App::Sysadmin::Log::Simple
# VERSION

use Carp;
use HTTP::Tiny;
use URI::Escape qw(uri_escape);

our $HTTP_TIMEOUT = 10;

=head1 DESCRIPTION

This provides a log method that sends the log via a HTTP request. Which
may perhaps be considered to be a 'REST' request. Put, Get and Post are
will work. Though you might not be shown to be sane for doing so.

=head1 METHODS

=head2 new

This creates a new App::Sysadmin::Log::Simple::HTTP object. It takes a hash
of options:

=head3 http

A hashref containing keys:

=over 4

=item uri - default: http://localhost

=item method - default: post

=back

=head3 user

The user to attribute the log entry to (not http user)

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    my $app   = $opts{app};

    $app->{http}->{uri} ||= 'http://localhost';
    $app->{http}->{method} ||= 'post';
    $app->{http}->{method} = uc $app->{http}->{method};

    return bless {
        do_http => $app->{do_http},
        http    => $app->{http},
        user    => $app->{user},
    }, $class;
}

=head2 log

This connects to the remote server and sends the log entry out.

=cut

sub log {
    my $self     = shift;
    my $logentry = shift;

    return unless $self->{do_http};

    my $ua = HTTP::Tiny->new(
        timeout => $HTTP_TIMEOUT,
        agent   => __PACKAGE__ . '/' . (__PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev'),
    );
    my $res = sub {
        if ( $self->{http}->{method} eq 'GET' ) {
            my $params = $ua->www_form_urlencode({
                user => $self->{user},
                log  => $logentry,
            });
            my $uri = $self->{http}->{uri} . "?$params";

            return $ua->get($uri);
        }
        elsif ( $self->{http}->{method} eq 'POST' ) {
            return $ua->post_form($self->{http}->{uri}, {
                user => $self->{user},
                log  => $logentry,
            });
        }
        elsif ( $self->{http}->{method} eq 'PUT' ) {
            return $ua->put($self->{http}->{uri}, {
                user => $self->{user},
                log  => $logentry,
            });
        }
        else {
           croak 'This shouldnt happen, as the method is populated internally. Something bad has happened'
        }
    }->();

    carp sprintf('Failed to http log via %s to %s with code %d and error %s',
		$self->{http}->{method},
        $self->{http}->{uri},
        $res->{status},
        $res->{reason},
    ) unless $res->{success};

    return "Logged to $self->{http}->{uri} via $self->{http}->{method}"
}

1;

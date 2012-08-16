package App::Sysadmin::Log::Simple::Http;
use strict;
use warnings;
use Carp;
#use autodie qw(:socket); # fail, i dont know how to use autodie

my $HTTP_TIMEOUT = 10;

# ABSTRACT: a HTTP (maybe RESTful?) based logger for App::Sysadmin::Log::Simple
# VERSION

=head1 DESCRIPTION

This provides a log method that sends the log via a HTTP request. Which
may perhaps be considered to be a 'REST' request. Put, Get and Post are
will work. Though you might not be shown to be sane for doing so.

=head1 METHODS

=head2 new

This creates a new App::Sysadmin::Log::Simple::Http object. It takes a hash
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

    my $ua = LWP::UserAgent->new;
    $ua->timeout($HTTP_TIMEOUT);
    my $res;

    if ( lc $self->{http}->{method} eq 'get' ) {

        my $uri = $self->{http}->{uri};
        $uri .= ($uri =~ m/\?/) ? '&' : '?';
        $uri .= sprintf('user=%s&log=%s',$self->{user},$logentry); #FIXME these need to be escapted

        $res = $ua->get($uri);

    } elsif ( lc $self->{http}->{method} eq 'post' ) {

        $res = $ua->post($self->{http}->{uri}, { user => $self->{user}, log => $logentry });

    } elsif ( lc $self->{http}->{method} eq 'put' ) {

        $res = $ua->put($self->{http}->{uri}, { user => $self->{user}, log => $logentry });

    }

    carp sprintf('Failed to http log via %s to %s with code %d and error %s',
		$self->{http}->{method},$self->{http}->{uri},$res->code,$res->status_line);

    return "Logged to $self->{http}->{uri} via $self->{http}->{method}"
}

1;

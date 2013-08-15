package App::Sysadmin::Log::Simple::Twitter;
use strict;
use warnings;
use autodie qw(:file :filesys);
use Config::General qw(ParseConfig);
use Path::Tiny;

# ABSTRACT: a Twitter-logger for App::Sysadmin::Log::Simple
# VERSION

=head1 DESCRIPTION

This provides a log method that publishes your log entry to a Twitter feed.

=head1 METHODS

=head2 new

This creates a new App::Sysadmin::Log::Simple::Twitter object.

You're required to register this application at L<https://dev.twitter.com>, and
provide the consumer key, consumer secret, access token, and access token
secret. Upon registering the application, get the consumer key and secret from
the app details view. To get the I<access> key and secret, click "My Access
Token" on the right sidebar.

These data should be placed in a private (C<chmod 600>) file in
F<$HOME/.sysadmin-log-twitter-oauth>:

    consumer_key        =   ...
    consumer_secret     =   ...
    oauth_token         =   ...
    oauth_token_secret  =   ...

Or, you can provide a different location for the file:

    my $logger = App::Sysadmin::Log::Simple::Twitter->new(
        oauth_file => '/etc/twitter',
    );

=cut

sub new {
    my $class = shift;
    my %opts  = @_;
    my $app   = $opts{app};

    my $oauth_file;
    if ($app->{oauth_file}) {
        $oauth_file = $app->{oauth_file};
    }
    else {
        require File::HomeDir;

        my $HOME = File::HomeDir->users_home(
            $app->{user} || $ENV{SUDO_USER} || $ENV{USER}
        );
        $oauth_file = path($HOME, '.sysadmin-log-twitter-oauth');
    }

    return bless {
        oauth_file  => $oauth_file,
        do_twitter  => $app->{do_twitter},
    }, $class;
}

=head2 log

This tweets your log message.

=cut

sub log {
    my $self     = shift;
    my $logentry = shift;

    return unless $self->{do_twitter};

    require Net::Twitter::Lite::WithAPIv1_1;

    warn "You should do: chmod 600 $self->{oauth_file}\n"
        if ($self->{oauth_file}->stat->mode & 07777) != 0600; ## no critic (ValuesAndExpressions::ProhibitLeadingZeros)
    my $conf = Config::General->new($self->{oauth_file});
    my %oauth = $conf->getall();

    my $ua = __PACKAGE__
        . '/' . (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev');
    my $t = Net::Twitter::Lite::WithAPIv1_1->new(
        consumer_key        => $oauth{consumer_key},
        consumer_secret     => $oauth{consumer_secret},
        access_token        => $oauth{oauth_token},
        access_token_secret => $oauth{oauth_token_secret},
        ssl                 => 1,
        useragent           => $ua,
    );
    $t->access_token($oauth{oauth_token});
    $t->access_token_secret($oauth{oauth_token_secret});

    my $result = $t->update($logentry);
    die 'Something went wrong' unless $result->{text} eq $logentry;

    my $url = 'https://twitter.com/'
        . $result->{user}->{screen_name}
        . '/status/' . $result->{id_str};
    return "Posted to Twitter: $url";
}

1;

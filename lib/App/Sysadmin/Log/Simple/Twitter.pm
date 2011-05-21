package App::Sysadmin::Log::Simple::Twitter;
use perl5i::2;
# ABSTRACT: a Twitter-logger for App::Sysadmin::Log::Simple
# VERSION
use Config::General qw(ParseConfig);

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

method new($class: %opts) {
    my $oauth_file;
    if ($opts{oauth_file}) {
        $oauth_file = $opts{oauth_file};
    }
    else {
        require File::HomeDir;
        my $HOME = File::HomeDir->users_home(
            $opts{user} || $ENV{SUDO_USER} || $ENV{USER}
        );
        $oauth_file = "$HOME/.sysadmin-log-twitter-oauth";
    }

    return bless {
        oauth_file  => $oauth_file,
        twitter     => $opts{twitter},
    }, $class;
}

=head2 log

This tweets your log message.

=cut

method log($logentry) {
    return unless $self->{twitter};

    require Net::Twitter::Lite;
    
    my $stat = stat $self->{oauth_file};
    warn "You should do: chmod 600 $self->{oauth_file}\n"
        if ($stat->mode & 07777) != 0600;
    my $conf = Config::General->new($self->{oauth_file});
    my %oauth = $conf->getall();

    my $ua = __PACKAGE__
        . '/' . (defined __PACKAGE__->VERSION ? __PACKAGE__->VERSION : 'dev');
    my $t = Net::Twitter::Lite->new(
        consumer_key    => $oauth{consumer_key},
        consumer_secret => $oauth{consumer_secret},
        useragent       => $ua,
    );
    $t->access_token($oauth{oauth_token});
    $t->access_token_secret($oauth{oauth_token_secret});

    my $result = $t->update($logentry);
    die "Something went wrong" unless $result->{text} eq $logentry;

    my $url = 'https://twitter.com/#!/'
        . $result->{user}->{screen_name}
        . '/status/' . $result->{id_str};
    return "Posted to Twitter: $url";
}

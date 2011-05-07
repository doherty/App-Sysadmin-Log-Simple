use strict;
use warnings;
use Test::More tests => 5;
use Test::Output;
use IO::Scalar;
require App::Sysadmin::Log::Simple;

my $rand = rand;
my $logentry = new IO::Scalar \$rand;

my $app = new_ok('App::Sysadmin::Log::Simple' => [
    logdir  => 't/log',
    date    => '2011/02/19',
    read_from => $logentry,
]);

stdout_is(
    sub { $app->run() },
    "Log entry:\n",
    'Got the log prompt'
);

stdout_like(
    sub { $app->run('view') },
    qr/\Q$rand\E/,
    "$rand appeared in the log"
);

stdout_is(
    sub { eval { $app->run() } },
    "Log entry:\n",
    'Log entry requested'
);
like $@, qr/A log entry is needed/, 'Logging with no entry is fatal';

END {
    open my $log, '>', 't/log/2011/2/19.log' or warn "Couldn't open file for writing: $!";
    print $log $_ while (<DATA>);
    close $log;
}

__DATA__
Saturday February 19, 2011
==========================

    14:36:49 mike:	hello
    14:38:14 mike:	hello

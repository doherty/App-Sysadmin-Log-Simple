use strict;
use warnings;
use Test::More tests => 2;
use Test::Output;
use IO::Scalar;
require App::Sysadmin::Log::Simple;

my $rand = rand;
my $logentry = new IO::Scalar \$rand;

my $app = App::Sysadmin::Log::Simple->new(
    logdir  => 't/log',
    date    => '2011/02/19',
    read_from => $logentry,
);

ok($app->run(), 'App ran OK (log)');

stdout_like(
    sub { $app->run('view') },
    qr/\Q$rand\E/,
    "$rand appeared in the log"
);

END {
    open my $log, '>', 't/log/2011/2/19.log' or die "Couldn't open file for writing: $!";
    print $log $_ while (<DATA>);
    close $log;
}

__DATA__
Saturday February 19, 2011
==========================

    14:36:49 mike:	hello
    14:38:14 mike:	hello

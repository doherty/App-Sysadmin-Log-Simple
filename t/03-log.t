use strict;
use warnings;
use Test::Cmd;
use Test::More tests => 2;

my $test = Test::Cmd->new(
    prog    => './bin/log',
    workdir => '',
    # verbose => 1,
    interpreter => 'perl -Ilib',
);
my $tmplog = '--logdir ' . $test->workdir;

my $rand = rand;

$test->run(
    args    => "--date 2011/02/19 --no-udp $tmplog",
    stdin   => $rand,
);
is($?, 0, 'Log OK');

$test->run(
    args    => "--view --date 2011/02/19 $tmplog",
);
like($test->stdout, qr/\Q$rand\E/, 'Old log data is there');

END {
    $test->cleanup;
}

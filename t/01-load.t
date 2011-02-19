use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok('App::Sysadmin::Log::Simple');
}
my $logger = new_ok('App::Sysadmin::Log::Simple' => [
    logdir  => 't/log',
    user    => $ENV{USER},
]);
can_ok($logger, qw(new run _add_to_log _generate_index _to_udp _view_log));

use strict;
use warnings;
use Test::More tests => 9;

BEGIN {
    use_ok('App::Sysadmin::Log::Simple');
    use_ok('App::Sysadmin::Log::Simple::File');
    use_ok('App::Sysadmin::Log::Simple::UDP');
}
my $logger = new_ok('App::Sysadmin::Log::Simple');
can_ok($logger, qw(new run run_command run_command_log run_command_view));

my $file_logger = new_ok('App::Sysadmin::Log::Simple::File');
can_ok($file_logger, qw(new log view));

my $udp_logger = new_ok('App::Sysadmin::Log::Simple::UDP');
can_ok($udp_logger, qw(new log));

use strict;
use warnings;
use autodie qw(:file :filesys);
use File::Spec;
use Test::Output qw(output_from);
use Test::More 0.96 tests => 4;
use IO::Scalar;
use App::Sysadmin::Log::Simple;

my $rand = rand;
my $logentry = IO::Scalar->new(\$rand);
$ENV{'App::Sysadmin::Log::Simple::File under test'} = 1;
my $app = new_ok('App::Sysadmin::Log::Simple' => [
    logdir  => 't/log',
    date    => '2011/02/19',
    read_from => $logentry,
]);

subtest 'log' => sub {
    plan tests => 4;
    my ($stdout, $stderr) = output_from { $app->run() };

    like $stdout, qr/Log entry:/m, 'Got the log prompt';
    like $stdout, qr/^\[UDP/m, 'UDP logger mentioned';
    like $stdout, qr/^\[File/m, 'File logger mentioned';
    is $stderr, '', 'No STDERR';
};

subtest 'view' => sub {
    plan tests => 1;
    my ($stdout, $stderr) = output_from { $app->run('view') };

    like $stdout, qr/\Q$rand\E/, "$rand appeared in the log";
};

subtest 'log-fail' => sub {
    plan tests => 2;
    my ($stdout, $stderr) = output_from { eval { $app->run() } };

    like $stdout, qr/Log entry:/, 'Log entry requested';
    like $@, qr/A log entry is needed/, 'Logging with no entry is fatal';
};

END {
    open my $log, '>', File::Spec->catfile(qw( t log 2011 2 19.log));
    print $log $_ while (<DATA>);
    close $log;
}

__DATA__
Saturday February 19, 2011
==========================

    14:36:49 mike:	hello
    14:38:14 mike:	hello

use strict;
use warnings;
use autodie qw(:file :filesys);
use Test::More tests => 1;
use Test::Output;
use App::Sysadmin::Log::Simple;

$ENV{'App::Sysadmin::Log::Simple::File under test'} = 1;
my $log = App::Sysadmin::Log::Simple->new(
    logdir  => 't/log',
    date    => '2011/02/19',
);

my $should = do { local $/; <DATA> };
open my $testfh, '>', 't/log/2011/2/19.log';
print $testfh $should;
close $testfh;

stdout_is sub { $log->run('view') }, $should, 'Reads the file ok';

__DATA__
Saturday February 19, 2011
==========================

    14:36:49 mike:	hello
    14:38:14 mike:	hello

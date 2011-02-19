use strict;
use warnings;
use Test::More tests => 1;
use Test::Output;
require App::Sysadmin::Log::Simple;

my $log = App::Sysadmin::Log::Simple->new(
    logdir  => 't/log',
    user    => $ENV{USER},
    date    => '2011/02/19',
);

my $should = do { local $/; <DATA> };
open my $testfh, '>', 't/log/2011/2/19.log' or die "Couldn't open for reading: $!";
print $testfh $should;
close $testfh or die "Couldn't close filehandle: $!";

stdout_is(sub { $log->run('view') }, $should, 'Reads the file ok');

__DATA__
Saturday February 19, 2011
==========================

    14:36:49 mike:	hello
    14:38:14 mike:	hello

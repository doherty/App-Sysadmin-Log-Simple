use perl5i::2;
use File::Temp;
use Test::More tests => 2;
require App::Sysadmin::Log::Simple;

my $log = App::Sysadmin::Log::Simple->new(
    logdir  => 't/log',
);

my $year  = 2011;
my $month = 2;
my $day   = 18;

my $idx_old = do { local $/; open my $idxfh, '<', "t/log/index.log"; <$idxfh> };

open my $newlog, '>', "t/log/$year/$month/$day.log";
print $newlog "ohaithar";
close $newlog;

$log->run('refresh-index');

my $idx_new = do { local $/; open my $idxfh, '<', "t/log/index.log"; <$idxfh> };

isnt($idx_old, $idx_new, 'The index did change');
like($idx_new, qr{\Q($year/$month/$day)\E}, 'The date we wanted appears in the index');

END { # Set things back the way they were
    unlink "t/log/$year/$month/$day.log";
    $log->run('refresh-index');
}

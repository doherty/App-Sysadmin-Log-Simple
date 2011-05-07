use perl5i::2;
use File::Temp;
use Test::More tests => 4;
use Test::Output;
use IO::Scalar;
require App::Sysadmin::Log::Simple;

my $rand = rand;
my $logentry = IO::Scalar->new(\$rand);
my $year  = 2011;
my $month = 2;
my $day   = 18;

my $log = new_ok('App::Sysadmin::Log::Simple' => [
    logdir      => 't/log',
    read_from   => $logentry,
    date        => "$year/$month/$day",
]);
my $idx_old = do { local $/; open my $idxfh, '<', "t/log/index.log"; <$idxfh> };

stdout_is(
    sub { $log->run() }, # will read from $logentry
    "Log entry:\n",
    'log ok'
);

my $idx_new = do { local $/; open my $idxfh, '<', "t/log/index.log"; <$idxfh> };

isnt($idx_old, $idx_new, 'The index did change');
like($idx_new, qr{\Q($year/$month/$day)\E}, 'The date we wanted appears in the index');

END { # Set things back the way they were
    unlink "t/log/$year/$month/$day.log" if -e "t/log/$year/$month/$day.log";
    require App::Sysadmin::Log::Simple::File;
    my $file_logger = App::Sysadmin::Log::Simple::File->new(logdir  => 't/log');
    $file_logger->_generate_index();
}

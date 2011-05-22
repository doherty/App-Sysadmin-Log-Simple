use perl5i::2;
use File::Temp;
use Test::More tests => 5;
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

my ($stdout, $stderr) = capture { $log->run() }; # will read from $logentry
like $stdout, qr/Log entry:/, 'log ok';
is $stderr, '', 'No STDERR';

my $idx_new = do { local $/; open my $idxfh, '<', "t/log/index.log"; <$idxfh> };

isnt($idx_old, $idx_new, 'The index did change');
like($idx_new, qr{\Q($year/$month/$day)\E}, 'The date we wanted appears in the index');

END { # Set things back the way they were
    unlink "t/log/$year/$month/$day.log" if -e "t/log/$year/$month/$day.log";
    require App::Sysadmin::Log::Simple::File;
    my $file_logger = App::Sysadmin::Log::Simple::File->new(logdir  => 't/log');
    $file_logger->_generate_index();
}

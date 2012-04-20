
use strict;
use warnings;

use Module::Build 0.3601;


my %module_build_args = (
  "build_requires" => {
    "File::Find" => 0,
    "File::Temp" => 0,
    "IO::Scalar" => 0,
    "Module::Build" => "0.3601",
    "Test::More" => "0.96",
    "Test::Output" => 0
  },
  "configure_requires" => {
    "ExtUtils::MakeMaker" => "6.30",
    "Module::Build" => "0.3601"
  },
  "dist_abstract" => "application class for managing a simple sysadmin log",
  "dist_author" => [
    "Mike Doherty <doherty\@cpan.org>"
  ],
  "dist_name" => "App-Sysadmin-Log-Simple",
  "dist_version" => "0.005",
  "license" => "perl",
  "module_name" => "App::Sysadmin::Log::Simple",
  "recommends" => {},
  "recursive_test_files" => 1,
  "requires" => {
    "Carp" => 0,
    "Config::General" => 0,
    "DateTime" => 0,
    "File::Find::Rule" => 0,
    "File::HomeDir" => 0,
    "File::Path" => "2.07",
    "Getopt::Long" => 0,
    "IO::Pager" => 0,
    "IO::Socket::INET" => 0,
    "Module::Pluggable" => 0,
    "Net::Twitter::Lite" => 0,
    "Pod::Usage" => 0,
    "Try::Tiny" => 0,
    "autodie" => 0,
    "perl" => "v5.10.1",
    "perl5i::2" => 0,
    "strict" => 0,
    "warnings" => 0
  },
  "script_files" => [
    "bin/log"
  ]
);


my $build = Module::Build->new(%module_build_args);

$build->create_build_script;

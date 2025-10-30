#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use n2p_cpu;
use n2p_memory;
use n2p_clock;
use n2p_screen;
use n2p_functions qw(open_file print_debug debug_cpu clear_screen);
use Getopt::Long;

my $version     = '0.1-alpha';
my $file        = '';
my $debug       = 0;
my $speed       = 10000;
my $help        = 0;
my $version_out = 0;
my $screen      = 'none';

my %options = ();
GetOptions( \%options,
            'file=s'    => \$file,
            'debug'     => \$debug,
            'speed=i'   => \$speed,
            'help'      => \$help,
            'version'   => \$version_out,
            'screen=s'  => \$screen );

if ($help) {
  print <<EOF;
HELP TEXT INCOMING
EOF
  exit;
}

clear_screen();
print "nand2perl hack emulator v.$version\n";
exit if $version_out;

die "speed must be 0 or positive\n" if $speed < 0;
die "input file must be defined\n" if $file eq '';

print "initializing\n";
sleep(1);
my $cpu     = n2p_cpu->new();
my $mem     = n2p_memory->new();
my $clock   = n2p_clock->new($speed);
my $screen  = n2p_screen->new($screen,$mem);

open_file($mem, $file);

my ($mb, $mr, $ma, $ra) = (0,0,0,0);

print_debug("\"starting state\"",$debug);
print_debug(sprintf("mb: %016b mr: %01b ma: %016b ra: %016b",$mb,$mr,$ma,$ra),$debug);
debug_cpu($cpu,$debug);
print "\n" if $debug;

while(1) {
  $clock->tick();

  # tick
  $cpu->tick($mem->rom($ra), $mem->ram($ma, $mr, $mb), 0);

  # tock
  ($mb, $mr, $ma, $ra) =
    $cpu->tock($mem->rom($ra), $mem->ram($ma, $mr, $mb), 0);
  print_debug(sprintf("mb: %016b mr: %01b ma: %016b ra: %016b",$mb,$mr,$ma,$ra),$debug);
  debug_cpu($cpu,$debug);
  print "\n" if $debug;

  $screen->display($mem);
}
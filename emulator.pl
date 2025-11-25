#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use n2p_cpu;
use n2p_memory;
use n2p_clock;
use n2p_screen;
use n2p_functions qw(open_file print_debug debug_cpu 
  debug_instruction clear_screen get_keyboard);
use Getopt::Long;
use Term::ReadKey;

ReadMode('cbreak');

$SIG{INT} = sub {
  ReadMode('restore');
  print "\e[?25h\e[H";
  exit;
};

my $version     = '0.1-alpha';
my $file        = '';
my $debug       = 0;
my $speed       = 10000;
my $help        = 0;
my $version_out = 0;
my $screen_mode = 'none';
my $wait        = 0;

my %options = ();
GetOptions( \%options,
            'file=s'    => \$file,
            'debug'     => \$debug,
            'wait'      => \$wait,
            'speed=i'   => \$speed,
            'help'      => \$help,
            'version'   => \$version_out,
            'screen=s'  => \$screen_mode );

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
my $screen  = n2p_screen->new($screen_mode,$mem);

open_file($mem, $file);

my ($mb, $mwr, $ma, $ra) = (0,0,0,0);

print_debug("\"starting state\"",$debug);
debug_instruction($ra,$mem->rom($ra),$debug);
print_debug(sprintf("mb: %016b mwr: %01b ma: %016b ra: %016b",$mb,$mwr,$ma,$ra),$debug);
print_debug(sprintf("keyboard: %016b", $mem->ram(24576,0,24576)),$debug);
debug_cpu($cpu,$debug);
print "\n" if $debug;

while(1) {
  # handle keyboard input real quick
  get_keyboard($mem);

  $clock->tick();

  # tick
  $cpu->tick($mem->rom($ra), $mem->ram($ma, $mwr, $mb), 0);

  # tock
  ($mb, $mwr, $ma, $ra) =
    $cpu->tock($mem->rom($ra), $mem->ram($ma, $mwr, $mb), 0);

  $screen->display($mem, $cpu);
  print "\n";
  debug_instruction($ra,$mem->rom($ra),$debug);
  print_debug(sprintf("mb: %016b mwr: %01b ma: %016b ra: %016b",$mb,$mwr,$ma,$ra),$debug);
  print_debug(sprintf("keyboard: %016b", $mem->ram(24576,0,24576)),$debug);
  debug_cpu($cpu,$debug);
  print "\n" if $debug;
}
#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use n2p_cpu;
use n2p_memory;
use n2p_clock;
use n2p_functions qw(open_file);

my $cpu     = n2p_cpu->new();
my $memory  = n2p_memory->new();
my $clock   = n2p_clock->new(1000000);

open_file($memory, 'test.hack');

my ($mr, $ram_add, $rom_add, $mem_data) = (0,0,0,0);

print "starting state\n";
$cpu->_debug();
printf "rom: %016b ram: %016b: mr: %01b ram_add: %016b rom_add: %016b\n",
  $memory->rom($rom_add), $memory->ram($ram_add, $mr, $mem_data),
  $mr, $ram_add, $rom_add;

while(1) {
  print "tick\n";
  # tick
  $cpu->tick($memory->rom($rom_add), $memory->ram($ram_add, $mr, $mem_data), 0);

  # tock
  ($mem_data, $mr, $ram_add, $rom_add) =
    $cpu->tock($memory->rom($rom_add), $memory->ram($ram_add, $mr, $mem_data), 0);

  $cpu->_debug();
  printf "rom: %016b ram: %016b: mr: %01b ram_add: %016b rom_add: %016b\n",
    $memory->rom($rom_add), $memory->ram($ram_add, $mr, $mem_data),
    $mr, $ram_add, $rom_add;

  $clock->tick();
}
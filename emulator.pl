#!/usr/bin/perl

use strict;
use warnings;
use lib 'lib';
use n2p_cpu;

my $cpu = n2p_cpu->new();

my ($ram, $mr, $addr, $pc) = (0,0,0,0);
my $rom = 0b1110111111001000;
 
$cpu->_debug();
printf "%016b %01b %016b %016b\n", $ram, $mr, $addr, $pc;
$cpu->tick($rom,0,0);
($ram, $mr, $addr, $pc) = $cpu->tock($rom,0,0);
$cpu->_debug();
printf "%016b %01b %016b %016b\n", $ram, $mr, $addr, $pc;
$cpu->tick($rom,0,0);
($ram, $mr, $addr, $pc) = $cpu->tock($rom,0,0);
$cpu->_debug();
printf "%016b %01b %016b %016b\n", $ram, $mr, $addr, $pc;

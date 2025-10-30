#!/usr/bin/perl

package n2p_functions;
use strict;
use warnings;
use lib 'lib';
use n2p_memory;
use Exporter 'import';

our @EXPORT_OK = qw(open_file print_debug debug_cpu clear_screen);

sub open_file {
  my ($memory, $file) = @_;

  open my $fh, '<', $file or die "Can't open $file: $!";

  my $addr = 0;

  if ($file =~ /\.bin$/i) {
    binmode $fh;
    while (read($fh, my $word, 2)) {
      my $val = unpack('n', $word);
      $memory->burn_rom($addr++, $val);
    }
  }
  elsif ($file =~ /\.hack$/i) {
    while (my $line = <$fh>) {
      chomp $line;
      my $val = oct("0b$line");
      $memory->burn_rom($addr++, $val);
    }
  }
  else {
    die "currently not supporting .asm files\n";
  }
}

sub print_debug {
  my ($msg, $debug) = @_;
  print "debug: $msg\n" if $debug;
}

sub debug_cpu {
  my ($cpu, $debug) = @_;

  if ($debug) {
    my ($a_reg, $d_reg, $pc_reg, $alu_in_y, $alu_out, $alu_busy) = $cpu->_debug();
    print "cpu debug:\n";
    printf "PC: %016b A: %016b\n", $pc_reg, $a_reg;
    printf "%016b -> ALU x\n", $d_reg;
    printf "ALU BUSY: %01b          |--> %016b\n", $alu_busy, $alu_out;
    printf "%016b -> ALU y\n", $alu_in_y;
  }
}

sub clear_screen {
  print "\e[2J\e[H";
#  system("clear");
}

1;

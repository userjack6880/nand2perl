#!/usr/bin/perl

package n2p_functions;
use strict;
use warnings;
use lib 'lib';
use n2p_memory;
use n2p_int_func qw(n2p_get_bit);
use Exporter 'import';
use Term::ReadKey;

our @EXPORT_OK = qw(open_file print_debug debug_cpu 
  clear_screen get_keyboard debug_instruction);

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

sub debug_instruction {
  my ($pc, $operation, $debug) = @_;

  if ($debug) {
    print "instruction $pc: ";
    if(n2p_get_bit($operation,15)) {
      my %comp_table = (
          0b0101010 => '0',
          0b0111111 => '1',
          0b0111010 => '-1',
          0b0001100 => 'D',
          0b0110000 => 'A',
          0b1110000 => 'M',
          0b0001101 => '!D',
          0b0110001 => '!A',
          0b1110001 => '!M',
          0b0001111 => '-D',
          0b0110011 => '-A',
          0b1110011 => '-M',
          0b0011111 => 'D+1',
          0b0110111 => 'A+1',
          0b1110111 => 'M+1',
          0b0001110 => 'D-1',
          0b0110010 => 'A-1',
          0b1110010 => 'M-1',
          0b0000010 => 'D+A',
          0b1000010 => 'D+M',
          0b0010011 => 'D-A',
          0b1010011 => 'D-M',
          0b0000111 => 'A-D',
          0b1000111 => 'M-D',
          0b0000000 => 'D&A',
          0b1000000 => 'D&M',
          0b0010101 => 'D|A',
          0b1010101 => 'D|M',
      );

      print "A" if n2p_get_bit($operation,5);
      print "D" if n2p_get_bit($operation,4);
      print "M" if n2p_get_bit($operation,3);
      print "=";
      my $comp = ($operation >> 6) & 0b1111111;
      printf "%s", $comp_table{$comp};
      print ";";
      print "<" if n2p_get_bit($operation,2);
      print "=" if n2p_get_bit($operation,1);
      print ">" if n2p_get_bit($operation,0);
      print "\n";
    }
    else {
      print "\@$operation\n";
    }
  }
}

sub clear_screen {
  print "\e[2J\e[H";
#  system("clear");
}

sub get_keyboard {
  my $mem = shift;
  
  my $key = ReadKey(-1);

  if (defined $key) {
    my $ascii = ord($key);
    $mem->ram(24576,1,$ascii);
  }
}

1;

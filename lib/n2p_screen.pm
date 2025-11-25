#!/usr/bin/perl

package n2p_screen;
use strict;
use warnings;
use lib 'lib';
use n2p_memory;

sub new {
  my ($class, $type) = @_;
  my $self = {
    type => $type
  };
  bless $self, $class;

  if ($self->{type} eq 'pixel') {
    die "pixel mode in development\n";
  }
  if ($self->{type} eq 'none') {
    print "no display mode, use '-debug' to show values\n";
  }
  elsif ($self->{type} eq 'text') {
    my $cols = 80;
    my $rows = 25;

    # initial border print
    print "\e[2J\e[?25l";
    my $hr = "+".("-" x $cols)."+\n";
    print $hr;
    for my $y (0 .. $rows - 1) {
      print "|", (" " x $cols), "|\n";
    }
    print $hr;
  }
  else {
    die "unsupported screen mode\n";
  }

  return $self;
}

sub display {
  my ($self, $mem, $cpu) = @_;

  if ($self->{type} eq 'pixel') {
    # nothing here
  }
  elsif ($self->{type} eq 'text') {
    my $offset = 16384;
    my $cols = 80;
    my $rows = 25;
    my @last_frame;
    my ($mem_loc, $char_val, $char, $index);

    my (undef, undef, $reg_pc, undef, undef, $alu_busy) = $cpu->_debug();

    printf "\e[%d;%dH%s", 2, 3, "\[NAND2PERL\]";
    printf "\e[%d;%dH%s%016b%s%01b", 30, 3, "PC ", $reg_pc, " BUSY ", $alu_busy;

    # refresh loop
    for my $y (0 .. $rows - 1) {
      for my $x (0 .. $cols - 1) {
        $mem_loc = $offset + $x + ($y * $cols);
        $char_val = $mem->ram($mem_loc, 0, 0);
        $char = $char_val ? chr($char_val) : ' ';

        $index = $y * $cols + $x;
        if (!defined $last_frame[$index] || $last_frame[$index] ne $char) {
          printf "\e[%d;%dH%s", $y + 4, $x + 2, $char;
          $last_frame[$index] = $char;
        }
      }
    }
  }
  else {
    return;
  }
}

1;

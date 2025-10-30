#!/usr/bin/perl

package n2p_cpu;
use strict;
use warnings;
use lib 'lib';
use n2p_int_func qw(n2p_get_bit);

sub new {
  my $class = shift;
  my $self = {
    # registers
    reg_a       => 0,
    reg_d       => 0,
    reg_pc      => 0,

    # ALU
    alu_in_y    => 0,
    alu_out     => 0,
    alu_busy    => 0,
  };
  bless $self, $class;
  return $self;
}

sub _debug {
  my $self = shift;
  return $self->{reg_a}, $self->{reg_d}, $self->{reg_pc}, 
    $self->{alu_in_y}, $self->{alu_out}, $self->{alu_busy};
}

sub _reset {
  my $self = shift;
  foreach my $pin_reg ( keys %$self ) {
    $self->{$pin_reg} = 0;
  }
}

sub tick {
  # CPU loads up data into pins on tick cycle
  my ($self, $pin_rom, $pin_ram, $pin_reset) = @_;

  # reset
  if ($pin_reset) {
    $self->_reset();
    return;
  }

  # extract instructions
  my $ins_op  = n2p_get_bit($pin_rom, 15);
  my $ins_a   = n2p_get_bit($pin_rom, 12);
  my $ins_d1  = n2p_get_bit($pin_rom, 5);
  my $ins_d2  = n2p_get_bit($pin_rom, 4);

  # load A register
  if ($ins_d1 or !$ins_op) {
    $self->{reg_a} = $ins_op
      ? $self->{alu_out} : $pin_rom;
  }

  # load D register
  $self->{reg_d} = $self->{alu_out}
    if $ins_d2 && $ins_op;

  # set ALU y input
  $self->{alu_in_y} = $ins_a
    ? $pin_ram : $self->{reg_a};
}

sub tock {
  my ($self, $pin_rom, $pin_ram, $pin_reset) = @_;

  # reset
  if ($pin_reset) {
    $self->_reset();
    return 0,0,0,0; # outputs are all zeros on reset
  }

  # extract instructions
  my $ins_op  = n2p_get_bit($pin_rom, 15);
  my $ins_c1  = n2p_get_bit($pin_rom, 11);  # zx
  my $ins_c2  = n2p_get_bit($pin_rom, 10);  # nx
  my $ins_c3  = n2p_get_bit($pin_rom, 9);   # zy
  my $ins_c4  = n2p_get_bit($pin_rom, 8);   # ny
  my $ins_c5  = n2p_get_bit($pin_rom, 7);   # f
  my $ins_c6  = n2p_get_bit($pin_rom, 6);   # no
  my $ins_mr  = n2p_get_bit($pin_rom, 3);
  my $ins_j2  = n2p_get_bit($pin_rom, 2);
  my $ins_j1  = n2p_get_bit($pin_rom, 1);
  my $ins_j0  = n2p_get_bit($pin_rom, 0);

  # perform ALU calculation
  if ($ins_op && !$self->{alu_busy}) {
    # first clock cycle
    $self->{alu_busy} = 1;

    my $alu_int_x = $self->{reg_d};
    my $alu_int_y = $self->{alu_in_y};

    # xz/xy
    $alu_int_x = 0 if $ins_c1;
    $alu_int_y = 0 if $ins_c3;

    # nz/ny
    $alu_int_x = ~$alu_int_x & 0xFFFF if $ins_c2;
    $alu_int_y = ~$alu_int_y & 0xFFFF if $ins_c4;

    if ($ins_c5) {
      # perform add
      $self->{alu_out} = ($alu_int_x + $alu_int_y) & 0xFFFF;
    }
    else {
      # perform and
      $self->{alu_out} = $alu_int_x & $alu_int_y;
    }

    $self->{alu_out} = ~$self->{alu_out} & 0xFFFF if $ins_c6;

    return $self->{alu_out}, 0, $self->{reg_a}, $self->{reg_pc};
  }
  else {
    # we're on the second clock cycle
    $self->{alu_busy} = 0;
  }

  # perform other operations if ALU is not busy
  if (!$self->{alu_busy}) {
    # get negative
    my $alu_ng = n2p_get_bit($self->{alu_out}, 15);

    # determine if zero, easy
    my $alu_zr = $self->{alu_out} ? 0 : 1;

    # determine if positive
    my $alu_pos = ($alu_ng or $alu_zr) ? 0 : 1;

    # determine jump
    my $jmp = ((($ins_j0 && $alu_pos) or
                ($ins_j1 && $alu_zr)  or
                ($ins_j2 && $alu_ng)) && $ins_op);

    # increment or jump PC
    if ($jmp) {
      $self->{reg_pc} = $self->{reg_a};
    }
    else {
      $self->{reg_pc}++ if $self->{reg_pc} < 32767;
    }

    my $mem_out = ($ins_op && $ins_mr) ? 1 : 0;

    return $self->{alu_out}, $mem_out, $self->{reg_a}, $self->{reg_pc};
  }
}

1;

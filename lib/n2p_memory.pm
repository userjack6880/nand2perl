#!/usr/bin/perl

package n2p_memory;
use strict;
use warnings;
use lib 'lib';
use n2p_int_func qw(n2p_get_keyboard);

sub new {
  my $class = shift;
  my $self = {
    # registers
    rom       => [ (0) x 32768 ],
    ram       => [ (0) x 16384 ],
    screen    => [ (0) x 8192 ],
  };
  bless $self, $class;
  return $self;
}

sub _reset {
  my $self = shift;
  $self->{ram}    = [ (0) x 16384 ];
  $self->{screen} = [ (0) x 8192 ];
}

sub rom {
  my ($self, $addr) = @_;
  die "rom address undefined: $addr" unless defined $self->{rom}[$addr];
  return $self->{rom}[$addr] & 0xFFFF;
}

sub burn_rom {
  my ($self, $addr, $mem_in) = @_;
  $self->{rom}[$addr] = $mem_in;
}

sub ram {
  my ($self, $addr, $wr, $mem_in) = @_;

  if ($addr < 16384) {
    die "ram address undefined: $addr" unless defined $self->{ram}[$addr];
    $self->{ram}[$addr] = $mem_in if $wr;
    return $self->{ram}[$addr] & 0xFFFF;
  }
  elsif ($addr < 24576) {
    my $screen_addr = $addr - 16384;
    die "screen address undefined: $addr"
      unless defined $self->{screen}[$screen_addr];
    $self->{screen}[$screen_addr] = $mem_in if $wr;
    return $self->{screen}[$screen_addr] & 0xFFFF;
  }
  elsif ($addr == 24576) {
    my $key = n2p_get_keyboard();
    return defined $key ? ord($key) & 0xFFFF : 0;
  }
  else {
    return 0;
  }
}

1;

#!/usr/bin/perl

package n2p_int_func;
use strict;
use warnings;
use Exporter 'import';
use Term::ReadKey;

our @EXPORT_OK = qw(n2p_get_bit n2p_get_keyboard);

sub n2p_get_bit {
  my ($value, $bit_index) = @_;
  return ($value & (1 << $bit_index)) ? 1 : 0;
}

sub n2p_get_keyboard {
  ReadMode('raw');
  my $key = ReadKey(-1);
  ReadMode('restore');
  return $key;
}

1;

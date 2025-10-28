#!/usr/bin/perl

package n2p_int_func;
use strict;
use warnings;
use Exporter 'import';

our @EXPORT_OK = qw(n2p_get_bit);

sub n2p_get_bit {
  my ($value, $bit_index) = @_;
  return ($value & (1 << $bit_index)) ? 1 : 0;
}

1;

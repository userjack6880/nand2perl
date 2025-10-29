#!/usr/bin/perl

package n2p_functions;
use strict;
use warnings;
use lib 'lib';
use n2p_memory;
use Exporter 'import';

our @EXPORT_OK = qw(open_file);

sub open_file {
  my ($memory, $file) = @_;

  open my $fh, '<', $file or die "Can't open $file: $!";

  if ($file =~ /\.hack$/i) {
    binmode $fh;
    my $addr = 0;
    while (read($fh, my $word, 2)) {
      my $val = unpack('n', $word);
      printf "burn: %016b\n", $val;
      $memory->burn_rom($addr++, $val);
    }
  }
  else {
    die "currently not supporting .asm files\n";
  }
}

sub interpret_asm {
}

1;

#!/usr/bin/perl

###############################################################################
# nand2perl disassembler
#
# note: while the full emulator has the n2p_get_bit function, it is written
#   here again so that disassembler.pl can be submitted as a standalone script
#   
# note: the same goes for other functions included in the lib directory of the
#   full emulator
#
# John Bradley 2025
###############################################################################

use strict;
use warnings;
use Getopt::Long;

my $version     = '1.0';
my $in_file     = '';
my $out_file    = '';
my $debug       = 0;
my $version_out = 0;
my $help        = 0;

my %options = ();
GetOptions( \%options,
  'in=s'      => \$in_file,
  'out=s'     => \$out_file,
  'debug'     => \$debug,
  'version'   => \$version_out,
  'help'      => \$help );

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
  # invalid comps
  0b1101010 => '',
  0b1111111 => '',
  0b1111010 => '',
  0b1001100 => '',
  0b1001101 => '',
  0b1001111 => '',
  0b1011111 => ''
);

my %jump_table = (
  0b000 => '',
  0b001 => 'JGT',
  0b010 => 'JEQ',
  0b011 => 'JGE',
  0b100 => 'JLT',
  0b101 => 'JNE',
  0b110 => 'JLE',
  0b111 => 'JMP'
);

sub print_debug {
  my $msg = shift;
  print "debug: $msg\n" if $debug;
}

sub open_file {
  my $in_file = shift;

  die "must be .bin or .hack file!\n" unless $in_file =~ /\.(bin|hack)$/;

  open my $fh, '<', $in_file or die "Can't open $in_file: $!";

  my @lines;

  if ($in_file =~ /\.hack$/i) {
    print_debug("text mode");
    while (my $line = <$fh>) {
      chomp $line;                # truncate newline
      my $val = oct("0b$line");   # convert string into binary literal, then numeric
      print_debug("val($val)");
      push @lines, $val;
    }
  }
  else {
    print_debug("binary mode");
    while (read($fh, my $word, 2)) {  # assume big-endian
      my $val = unpack('n', $word);   # interpret 2-byte as unsigned 16-bit integer
      print_debug("val($val)");
      push @lines, $val;
    }
  }

  return @lines;
}

sub write_file {
  my ($out_file, @lines) = @_;

  open my $fh, '>', $out_file or die "Can't open $out_file: $!";

  for my $line (@lines) {
    print $fh "$line\n";
  }
  close $fh;
}

sub get_bit {
  my ($value, $bit_index) = @_;
  return ($value & (1 << $bit_index)) ? 1 : 0;
}

if ($help) {
  print <<EOF;
Usage: disassembler [OPTIONS]

Options:
  -i, --in <filename>           Input file to process. Accepts files with .hack
                                  or .bin extensions
  -o, --out <filename>          Output file name. If no extension is provided,
                                  '.asm' will be appended to the name.
                                If no file name is provided, output is sent to 
                                  the command line.
  -d, --debug                   Enable debug mode.
  -v, --version                 Display version information and exit.
  -h, --help                    Show this help message and exit.
EOF
  exit;
}

print "nand2perl disassembler v.$version\n";
exit if $version_out;

# open the file and populate lines
print_debug("getting binary");
my @binary = open_file($in_file);

# decode the binary
my @asm = ();

foreach my $op (@binary) {
  # determine if c or a op
  if (get_bit($op,15)) {
    # c op
    # determine comp
    my $comp_val = ($op >> 6) & 0b1111111;   # bit shift and isolate 7 bits
    my $comp = $comp_table{$comp_val};

    # error check
    if ($comp eq '') {
      printf "invalid comp: %07b", $comp_val;
      die;
    }

    # determine dest
    my $dest = '';
    $dest .= "A" if get_bit($op,5);
    $dest .= "D" if get_bit($op,4);
    $dest .= "M" if get_bit($op,3);

    # determine jump
    my $jump = $jump_table{$op & 0b111};  # isolate the lowest 3 bits

    # now build the operation
    my $asm = '';

    # dest
    if ($dest ne '') {
      $asm .= "$dest=";
    }

    # comp
    $asm .= $comp;

    # jump
    if ($jump ne '') {
      $asm .= ";$jump";
    }

    print_debug(sprintf("c op: interpeted %016b as %s", $op, $asm));
    push @asm, $asm;
  }
  else {
    # a op
    print_debug("a op: \@$op");
    push @asm, "\@$op";   # should be safe, as bit 15 isn't used
  }
}

# write to file or command line
if ($out_file eq '') {
  print_debug("outputting to command line");
  foreach my $line (@asm) {
    print "$line\n";
  }
}
else {
  print_debug("writing to $out_file");
  write_file($out_file, @asm);
  print "interpreted $in_file and wrote to $out_file\n";
}


#!/usr/bin/perl

package n2p_clock;
use strict;
use warnings;
use Time::HiRes qw(usleep);

sub new {
  my ($class, $delay) = @_;
  my $self = {
    # registers
    delay => $delay // 0
  };
  bless $self, $class;
  return $self;
}

sub tick {
  my $self = shift;
  usleep($self->{delay}) if $self->{delay};
}

1;

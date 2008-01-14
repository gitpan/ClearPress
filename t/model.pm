package t::model;
use strict;
use warnings;
use base qw(ClearPress::model);
use Test::More;

sub fields {
  return qw(test_field);
}

sub test_field {
  my ($self, $val) = @_;
  if(defined $val) {
    $self->{test_field} = $val;
  }

  return $self->{test_field};
}

########
# disable reading from database
#
sub create { return 1; }
sub read   { return 1; } ## no critic
sub update { return 1; }
sub delete { return 1; } ## no critic

1;

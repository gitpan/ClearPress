package t::user::basic;
use strict;
use warnings;
use base qw(ClearPress::model);

sub fields {
  return qw(username);
}

sub is_member_of {
  my ($self, $groupname) = @_;
  return;
}

1;

package t::user::admin;
use strict;
use warnings;
use base qw(ClearPress::model);

sub fields {
  return qw(username);
}

sub is_member_of {
  my ($self, $groupname) = @_;
  if($groupname eq 'admin') {
    return 1;
  }
  return;
}

1;

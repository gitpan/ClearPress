package t::model::attribute;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(fields());

sub fields {
  return qw(id_attribute description);
}

1;

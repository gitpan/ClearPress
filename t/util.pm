package t::util;
use strict;
use warnings;
use base qw(ClearPress::util);

sub dbh {
  my $self = shift;
  return $self->{'dbh'};
}

1;

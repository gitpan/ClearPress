use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use Test::Trap;

eval {
  require DBD::SQLite;
  plan tests => 6;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

{
  my $util1 = t::util->new();
  my $util2 = t::util->new();
  is($util1, $util2, 'same singleton util instance');

  is($util1->dbh(), $util2->dbh(), 'same dbh from different utils');
}

{
  my $util1 = t::util::test1->new();
  my $util2 = t::util::test2->new();
  isnt($util1, $util2, 'different singleton util subclass instance');

  isnt($util1->dbh(), $util2->dbh(), 'different dbh from different utils');
}

{
  my $util1 = t::util::test1->new();
  my $util2 = t::util::test1->new();
  is($util1, $util2, 'same singleton util subclass instance');

  is($util1->dbh(), $util2->dbh(), 'same dbh from different util subclass instances');
}

package t::util::test1;
use base qw(t::util);

1;

package t::util::test2;
use base qw(t::util);

1;

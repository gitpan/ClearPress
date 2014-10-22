use strict;
use warnings;
use Test::More;

eval {
  require DBD::SQLite;
  plan tests => 2;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use t::model::derived;
use t::util;
use Test::Trap;

my $util = t::util->new();

{
  my $der = t::model::derived->new({util=>$util});
  trap {
    $der->hasa('derived_child');
  };
  like($trap->stderr(), qr/deprecated/mix);
}

{
  my $der = t::model::derived->new({util=>$util});
  trap {
    $der->hasmany('derived_child');
  };
  like($trap->stderr(), qr/deprecated/mix);
}

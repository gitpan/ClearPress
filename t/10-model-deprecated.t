use strict;
use warnings;
use Test::More tests => 2;
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

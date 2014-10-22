use strict;
use warnings;
use Test::More tests => 11;
use English qw(-no_match_vars);
use Test::Trap;

use_ok('ClearPress::driver');

{
  my $drv = ClearPress::driver->new({
				     drivername => 'test',
				     dbname     => 'test',
				     dbhost     => 'localhost',
				     dbuser     => 'user',
				     dbpass     => 'password',
				    });
  isa_ok($drv, 'ClearPress::driver');

  trap {
    my $dbh = $drv->dbh();
  };

  like($trap->stderr, qr/unimplemented/mx, 'unconfigured dbh');

  trap {
    $drv->create_table('foo');
  };
  like($trap->stderr(), qr/unimplemented/mx);

  is_deeply($drv->types(), {}, 'no type mappings by default');
  is($drv->type_map('foo'), 'foo', 'no map for type "foo"');
  is($drv->type_map(), undef, 'no map for type "undef"');
}

{
  my $drv1 = ClearPress::driver::test->new();
  my $drv2 = ClearPress::driver::test->new();
  isnt($drv1, $drv2, 'different instances - not singletons from ClearPress 1.20+');
}

{
  use_ok('ClearPress::driver::SQLite');
  use_ok('ClearPress::driver::mysql');

  my $drv1 = ClearPress::driver::SQLite->new();
  my $drv2 = ClearPress::driver::mysql->new();
  isnt($drv1, $drv2, 'different singleton instance');
}

package ClearPress::driver::test;
use base qw(ClearPress::driver);

1;

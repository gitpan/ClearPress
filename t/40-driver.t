use strict;
use warnings;
use Test::More tests => 7;
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

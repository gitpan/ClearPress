use strict;
use warnings;
use Test::More tests => 8;
use English qw(-no_match_vars);

if(-e 'test.db') {
  unlink 'test.db';
}


use_ok('ClearPress::driver::SQLite');

my $cfg = {
	   dbname     => 'test.db',
	   dbuser     => q[],
	   dbpass     => q[],
	   dbhost     => q[],
	   dbport     => q[],
	  };

{
  my $drv = ClearPress::driver::SQLite->new();
  isa_ok($drv, 'ClearPress::driver::SQLite');
}

#{
#  my $drv = ClearPress::driver::SQLite->new({dbname => });
#  eval {
#    my $dbh = $drv->dbh();
#  };
#  like($EVAL_ERROR, qr/Failed\ to\ connect/mix, 'eval error');
#}

{
  my $drv = ClearPress::driver::SQLite->new($cfg);
  isa_ok($drv, 'ClearPress::driver::SQLite');

  eval {
    $drv->create_table('derived', {});
  };
  like($EVAL_ERROR, qr/Could\ not/mx, 'create without pk');
}

{
  my $drv = ClearPress::driver::SQLite->new($cfg);
  isa_ok($drv, 'ClearPress::driver::SQLite');

  ok($drv->create_table('derived',
			{
			 id_derived  => 'primary key',
			 text_dummy  => 'text',
			 char_dummy  => 'char(128)',
			 int_dummy   => 'integer unsigned',
			 float_dummy => 'float unsigned',
			}), 'create table');
}

{
  my $drv = ClearPress::driver::SQLite->new($cfg);
  ok($drv->create(q[INSERT INTO derived(text_dummy) values('foo')]));
}

{
  my $drv = ClearPress::driver::SQLite->new($cfg);
  ok($drv->drop_table('derived'), 'drop table');
}


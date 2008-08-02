use strict;
use warnings;
use Test::More tests => 6;
use English qw(-no_match_vars);

use_ok('ClearPress::driver::mysql');

my $cfg = {
	   dbname     => 'test',
	   dbuser     => q[root],
	   dbpass     => undef,
	   dbhost     => q[localhost],
	   dbport     => q[3306],
	  };

my $drv = ClearPress::driver::mysql->new($cfg);
isa_ok($drv, 'ClearPress::driver::mysql');


{
  eval {
    $drv->create_table('derived', {});
  };
  like($EVAL_ERROR, qr/Could\ not/mx, 'create without pk');
}

{
  ok($drv->create_table('derived',
			{
			 id_derived  => 'primary key',
			 text_dummy  => 'text',
			 char_dummy  => 'char(128)',
			 int_dummy   => 'integer unsigned',
			 float_dummy => 'float unsigned',
			}, 'create table'));
}

ok($drv->create(q[INSERT INTO derived(text_dummy) values('foo')]));

ok($drv->drop_table('derived'), 'drop table');


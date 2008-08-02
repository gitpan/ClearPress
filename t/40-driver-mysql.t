use strict;
use warnings;
use Test::More tests => 3;
use English qw(-no_match_vars);

use_ok('ClearPress::driver::mysql');

my $drv = ClearPress::driver::mysql->new({
					  dbname => '___',
					  dbhost => 'localhost',
					  dbport => 65535,
					 });

{
  isa_ok($drv, 'ClearPress::driver::mysql');
}

{
  eval {
    my $dbh = $drv->dbh();
  };
  like($EVAL_ERROR, qr/Failed\ to\ connect/mix, 'eval error');
}

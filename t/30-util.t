use strict;
use warnings;
use Test::More tests => 12;
use English qw(-no_match_vars);
use Test::Trap;

use_ok('ClearPress::util');

{
  my $util = ClearPress::util->new();
  isa_ok($util, 'ClearPress::util');

  is($util->dbsection(), 'live', 'default dbsection');
  $ENV{dev} = 'test';
  is($util->dbsection(), 'test', 'ENV dbsection');

  is($util->configpath(), 'data/config.ini', 'default cnofigpath');
  is($util->configpath('t/data/config.ini'), 't/data/config.ini', 'user defined configpath');

  trap {
    ok($util->log(q[a message]), 'log yields true');
  };
  like($trap->stderr(), qr/a\ message/mx, 'stderr logging');

  trap {
    is($util->_accessor('key', 'value'), 'value', 'accessor set value');
    is($util->_accessor('key'), 'value', 'accessor get value');
  };

  like($trap->stderr(), qr/deprecated/smx, 'deprecated warn');

  is($util->quote(q['foo']), q['''foo''']);
}


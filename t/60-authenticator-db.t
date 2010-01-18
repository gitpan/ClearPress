use strict;
use warnings;
use Test::More tests => 7;
use t::util;

our $PKG = 'ClearPress::authenticator::db';
use_ok($PKG);
can_ok($PKG, qw(new authen_credentials));

my $util = t::util->new();

{
  my $auth = $PKG->new();
  isa_ok($auth, $PKG);
  isa_ok($auth, 'ClearPress::authenticator');
}

{
  my $auth = $PKG->new();
  is($auth->authen_credentials(), undef, 'no creds');
}

{
  my $auth = $PKG->new();
  is($auth->authen_credentials({username => 'dummy'}), undef, 'no password');
}

{
  my $auth = $PKG->new();
  is($auth->authen_credentials({password => 'dummy'}), undef, 'no username');
}

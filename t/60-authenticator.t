use strict;
use warnings;
use Test::More tests => 5;

our $PKG = 'ClearPress::authenticator';

use_ok($PKG);
can_ok($PKG, qw(new));

{
  my $auth = $PKG->new();
  isa_ok($auth, $PKG);
}

{
  my $auth = $PKG->new({
			foo => 'bar',
		       });
  isa_ok($auth, $PKG);
  is($auth->{foo}, 'bar', 'constructor value passthrough');
}

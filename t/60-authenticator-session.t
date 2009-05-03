use strict;
use warnings;
use Test::More tests => 12;
use MIME::Base64 qw(encode_base64);

our $PKG = 'ClearPress::authenticator::session';

use_ok($PKG);
can_ok($PKG, qw(authen_token));

{
  my $auth = $PKG->new();
  isa_ok($auth, $PKG);
}

{
  my $auth   = $PKG->new();
  my $cipher = $auth->cipher();
  isa_ok($cipher, 'Crypt::CBC');

  is($cipher, $auth->cipher(), 'primed cache cipher');
}

{
  my $auth = $PKG->new();
  my $key  = $auth->key();
  is($key, 'topsecretkey', 'default key');
}

{
  my $auth = $PKG->new({
			key => 'newsecretkey',
		       });
  my $key  = $auth->key();
  is($key, 'newsecretkey', 'key from constructor');
}

{
  my $auth = $PKG->new();
  $auth->key('othersecretkey');
  is($auth->key, 'othersecretkey', 'key from accessor');
}

{
  my $auth = $PKG->new();
  my $ref  = {
	      username => 'dummy',
	      metadata => 'stuff',
	     };
  my $encoded = $auth->encode_token($ref);
  my $decoded = $auth->decode_token($encoded);
  is_deeply($decoded, $ref, 'one-pass encode/decode');

  my $authen = $auth->authen_token($encoded);
  is_deeply($authen, $ref, 'authen_token pass-through to decode_token');
}

{
  my $auth    = $PKG->new();
  my $encoded = encode_base64('corruption');

  is($auth->authen_token($encoded), undef, 'failed decrypt');
}

{
  my $auth      = $PKG->new();
  my $cipher    = $auth->cipher;
  my $encrypted = $cipher->encrypt('corruption');
  my $encoded   = encode_base64($encrypted);

  is($auth->authen_token($encoded), undef, 'failed deyaml');
}

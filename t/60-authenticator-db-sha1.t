use strict;
use warnings;
use Test::More tests => 3;
use t::util;
use English qw(-no_match_vars);

eval {
  require Digest::SHA;
};

if($EVAL_ERROR) {
  plan skip_all => 'Digest::SHA not installed';
}

our $PKG = 'ClearPress::authenticator::db';
use ClearPress::authenticator::db;
my $util = t::util->new();
my $dbh  = $util->dbh();

{
  $dbh->do(q[CREATE TABLE user(username,pass)]);
  my $auth = $PKG->new({dbh=>$dbh});
  is($auth->authen_credentials({
				username => 'missing',
				password => 'something',
			       }), undef, 'unknown user');
  $dbh->do(q[DROP TABLE user]);
}

{
  my $crypt = Digest::SHA::sha1_hex('notthesame');
  $dbh->do(q[CREATE TABLE user(username,pass)]);
  $dbh->do(qq[INSERT INTO user(username,pass) VALUES('dummyuser','$crypt')]);
  my $auth = $PKG->new({dbh => $dbh});
  my $ref  = {
	      username => 'dummyuser',
	      password => 'dummypass',
	     };
  my $result = $auth->authen_credentials($ref);
  is_deeply($result, undef, 'valid user, bad password');
  $dbh->do(q[DROP TABLE user]);
}

{
  my $crypt = Digest::SHA::sha1_hex('dummy');
  $dbh->do(q[CREATE TABLE user(username,pass)]);
  $dbh->do(qq[INSERT INTO user(username,pass) VALUES('dummyuser','$crypt')]);
  my $auth = $PKG->new({dbh => $dbh});
  my $ref  = {
	      username => 'dummyuser',
	      password => 'dummy',
	     };
  my $result = $auth->authen_credentials($ref);
  is_deeply($result, $ref, 'valid user');
  $dbh->do(q[DROP TABLE user]);
}

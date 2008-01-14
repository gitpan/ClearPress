use strict;
use warnings;
use Test::More qw(no_plan);
use t::dbh;
use t::util;

use_ok('ClearPress::model');

my $mock = {
	    q(SELECT one, two FROM derived WHERE one=?:foobla) => [{
								    'one' => 'foobla',
								    'two' => 'blafoo',
								   }],
	   };
my $dbh  = t::dbh->new({'mock' => $mock});
my $util = t::util->new({'dbh'=>$dbh});

{
  my $model = ClearPress::model->new();
  isa_ok($model, 'ClearPress::model');
  is((scalar $model->fields()), undef, 'default model has no fields');
}

{
  my $derived = t::derived->new();
  my @fields = $derived->fields();
  is((scalar @fields), 2, 'derived class has two fields');
  is($derived->primary_key(), 'one', 'derived class has correct primary key');
  is($derived->table(), 'derived', 'derived class has correct table name');
  is(t::derived->table(), 'derived', 'derived class has correct table name via class method');
}

{
  my $ref     = {
		 'one' => 'foobla',
		 'util' => $util,
		};
  my $derived = t::derived->new($ref);
  is($derived->one(), 'foobla', 'defined field returns value');
  is($derived->two(), 'blafoo', 'undef field returns database value');
}

{
  isa_ok(t::derived->util(), 'ClearPress::util', 'util() class method returns a new util');
}

{
  my $derived = t::derived->new();
  eval {
    $derived->util();
  };
  like($@, qr/No\ utility\ object\ available/mx, 'die if util not present in an object');
}

package t::derived;
use strict;
use warnings;
use base qw(ClearPress::model);

sub fields {
  return qw(one two);
}

sub one {
  my $self = shift;

  if(scalar @_) {
    $self->set('one', @_);
  }
  return $self->get('one', @_);
}

sub two {
  my $self = shift;

  if(scalar @_) {
    $self->set('two', @_);
  }
  return $self->get('two', @_);
}

1;

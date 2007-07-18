
package GrandKids::model::family;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(__PACKAGE__->fields());

sub fields {
  return qw(id_family
	    
	    address city name state zip );
}

sub families {
  my $self = shift;
  return $self->gen_getall();
}




sub children {
  my $self  = shift;
  my $pkg   = 'GrandKids::model::child';
  my $query = qq(SELECT @{[join q(, ), $pkg->fields()]}
                 FROM   @{[$pkg->table()]}
                 WHERE  id_family = ?);
  return $self->gen_getarray($pkg, $query, $self->id_family());
}


1;

 

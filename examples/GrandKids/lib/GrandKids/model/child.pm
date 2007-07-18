
package GrandKids::model::child;
use strict;
use warnings;
use base qw(ClearPress::model);

__PACKAGE__->mk_accessors(__PACKAGE__->fields());

sub fields {
  return qw(id_child
	    id_family 
	    birthday name );
}

sub children {
  my $self = shift;
  return $self->gen_getall();
}


sub family {
  my $self  = shift;
  my $pkg   = 'GrandKids::model::family';
  return $pkg->new({
		    'util' => $self->util(),
		    'id_family' => $self->id_family(),
		   });
}




1;

 

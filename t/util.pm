package t::util;
use strict;
use warnings;
use base qw(ClearPress::util);
use Carp;

$ENV{dev} = q[test];

sub new {
  my ($class, @args) = @_;

  if(-e 'test.db') {
    unlink 'test.db';
  }

  my $self = $class->SUPER::new(@args);
  my $drv  = $self->driver();

  $drv->create_table('derived',
		     {
		      id_derived  => 'primary key',
		      id_derived_parent => 'integer unsigned',
		      id_derived_status => 'integer unsigned',
		      text_dummy  => 'text',
		      char_dummy  => 'char(128)',
		      int_dummy   => 'integer unsigned',
		      float_dummy => 'float unsigned',
		     });

  $drv->create_table('derived_parent',
		     {
		      id_derived_parent  => 'primary key',
		      text_dummy  => 'text',
		     });
  $drv->create_table('derived_child',
		     {
		      id_derived_child  => 'primary key',
		      id_derived  => 'integer unsigned',
		      text_dummy  => 'text',
		     });

  $drv->create_table('derived_status',
		     {
		      id_derived_status  => 'primary key',
		      id_status   => 'integer unsigned',
		     });
  $drv->create_table('status',
		     {
		      id_status  => 'primary key',
		      description  => 'text',
		     });
  $drv->create_table('derived_attr',
		     {
		      id_derived_attr => 'primary key',
		      id_attribute    => 'integer unsigned',
		      id_derived      => 'integer unsigned',
		     });
  $drv->create_table('attribute',
		     {
		      id_attribute => 'primary key',
		      description  => 'text',
		     });

  return $self;
}

sub data_path {
  my ($self, $data_path) = @_;
  if(defined $data_path) {
    $self->{data_path} = $data_path;
  }
  return $self->{data_path} || 't/data';
}

sub requestor {
  my ($self, $user) = @_;

  if($user) {
    if(ref $user) {
      $self->{requestor} = $user;
    } else {
      croak q[Cannot handle non object requestors];
    }
  }

  return $self->{requestor};
}

sub DESTROY {
  my $self = shift;
  if($self->{driver}) {
    $self->{driver}->DESTROY();
  }

  if(-e 'test.db') {
    unlink 'test.db';
  }
}

1;

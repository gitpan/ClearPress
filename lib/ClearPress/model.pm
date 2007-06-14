#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2007/06/14 14:42:42 $
# Id:            $Id: model.pm,v 1.2 2007/06/14 14:42:42 zerojinx Exp $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/model.pm,v $
# $HeadURL$
#
package ClearPress::model;
use strict;
use warnings;
use base qw(Class::Accessor);
use ClearPress::util;
use English qw(-no_match_vars);
use Carp;

our $VERSION = do { my ($r) = q$LastChangedRevision: 41 $ =~ /(\d+)/mx; $r; };

sub fields { return (); }

sub primary_key {
  my $self = shift;
  return ($self->fields())[0];
}

sub table {
  my $self = shift;
  my $tbl  = (ref $self) || $self;
  ($tbl)   = $tbl =~ /.*::([^:]+)/mx;
  return $tbl;
}

sub init  { }

sub new {
  my ($class, $defs) = @_;
  $defs ||= {};
  bless $defs, $class;

  $defs->init($defs);

  return $defs;
}

sub util {
  my $self = shift;
  if(!ref $self) {
    #########
    # If we're being accessed as a class method (e.g. for retrieving type dictionaries)
    # Then play nicely and return a util.
    #
    return ClearPress::util->new();
  }

  if(!$self->{'util'}) {
    croak q(No utility object available caller=) . caller;
  }
  return $self->{'util'};
}

sub get {
  my ($self, $field) = @_;

  if(!exists $self->{$field}) {
    $self->read();
  }

  return $self->SUPER::get($field);
}

sub gen_getarray {
  my $self  = shift;
  my $class = shift;
  my $query = shift;

  if(!ref $self) {
    $self = $self->new();
  }

  my @res = ();
  my $sth;

  eval {
    if($query =~ /\?/mx) {
      $sth = $self->util->dbh->prepare_cached($query, {}, 3); # see perldoc DBI for prepare_cached collision handling

    } else {
      $sth = $self->util->dbh->prepare($query);
    }
    $sth->execute(@_);
  };

  if($EVAL_ERROR) {
    carp $EVAL_ERROR . 'caller = '. caller;
    $query =~ s/\s+/\ /smxg;
    local $LIST_SEPARATOR = q(, );
    carp qq(Query was:\n$query\n\nParams: @_);
    return;
  }

  while(my $ref = $sth->fetchrow_hashref()) {
    $ref->{'util'} = $self->util();
    push @res, $class->new($ref);
  }
  return \@res;
}

sub gen_getall {
  my ($self, $class) = @_;
  $class ||= ref $self;
  return $self->gen_getarray($class,
			     qq(SELECT   @{[join q(, ), $class->fields()]}
                                FROM     @{[$class->table()]}
                                ORDER BY @{[$class->primary_key()]}));
}

sub create {
  my $self     = shift;
  my $util     = $self->util();
  my $dbh      = $util->dbh();
  my $pk       = $self->primary_key();
  my $tr_state = $util->transactions();
  my $table    = $self->table();

  if(!$table) {
    croak q(No table defined);
  }

  my $query = qq(INSERT INTO $table (@{[join q(, ), $self->fields()]})
                 VALUES (@{[join q(, ), map { q(?) } $self->fields()]}));
  eval {
    $dbh->do($query, {}, map { $self->{$_} || q() } $self->fields());

    #########
    # add 'sequence' support here for Oracle
    #
    my $idref = $dbh->selectall_arrayref('SELECT LAST_INSERT_ID()');
    $self->$pk($idref->[0]->[0]);
  };

  if($EVAL_ERROR) {
    $tr_state and $dbh->rollback();
    croak $EVAL_ERROR;
  }

  eval {
    $tr_state and $dbh->commit();
  };

  if($EVAL_ERROR) {
    $tr_state and $dbh->rollback();
    croak $EVAL_ERROR;
  }

  return 1;
}

sub read { ## no critic
  my $self  = shift;
  my $query = shift;
  my $pk    = $self->primary_key();

  if(!$query && !$self->{$pk}) {
#    carp q(No primary key);
    return;
  }

  my $table = $self->table();
  if(!$table) {
    croak q(No table defined);
  }

  if(!$self->{'_loaded'}) {
    my @args = @_;
    if(!$query) {
      $query = qq(SELECT @{[join q(, ), $self->fields()]}
                  FROM   $table
                  WHERE  $pk=?);
      @args = ($self->{$pk});
    }

    eval {
      my $sth   = $self->util->dbh->prepare($query);
      $sth->execute(@args);

      my $ref   = $sth->fetchrow_hashref();
      for my $f ($self->fields()) {
	$self->{$f} = $ref->{$f};
      }

      $sth->finish();
    };

    if($EVAL_ERROR) {
      croak $EVAL_ERROR.$query;
    }
  }
  $self->{'_loaded'} = 1;
  return $self;
}

sub update {
  my $self  = shift;
  my $util  = $self->util();
  my $dbh   = $util->dbh();
  my $pk    = $self->primary_key();

  if(!$pk || !$self->$pk()) {
    croak q(No primary key);
  }

  my $table = $self->table();
  if(!$table) {
    croak q(No table defined);
  }

  my $query = qq(UPDATE @{[$self->table()]}
                 SET    @{[join q(, ), map { qq($_ = ?) } $self->fields()]}
                 WHERE  $pk=@{[$self->$pk()]});
  eval {
    $dbh->do($query, {}, map { $self->$_() || q() } $self->fields());
  };

  if($EVAL_ERROR) { 
    $dbh->rollback();
    croak $EVAL_ERROR.$query;
  }

  if($util->transactions()) {
    eval {
      $dbh->commit();
    };
    if($EVAL_ERROR) {
      croak $EVAL_ERROR;
    }
  }
    
  return 1;
}

sub delete { ## no critic
  my $self = shift;
  my $util = $self->util();
  my $dbh  = $util->dbh();
  my $pk   = $self->primary_key();

  if(!$pk || !$self->$pk()) {
    croak q(No primary key);
  }

  my $query = qq(DELETE FROM @{[$self->table()]}
                 WHERE $pk=?);
  eval {
    $dbh->do($query, {}, $self->$pk());
    if($util->transactions()) {
      $dbh->commit();
    }
  };

  if($EVAL_ERROR) {
    $dbh->rollback();
    croak $EVAL_ERROR.$query;
  }
  return 1;
}

sub save {
  my $self = shift;
  my $pk   = $self->primary_key();

  if($pk && exists $self->{$pk}) {
    return $self->update();
  }

  return $self->create();
}

1;
__END__

=head1 NAME

ClearPress::model - a base class for the data-model of the ClearPress MVC family

=head1 VERSION

$LastChangedRevision: 41 $

=head1 SYNOPSIS

 use strict;
 use warning;
 use base qw(ClearPress::model);

 __PACKAGE__->mk_accessors(__PACKAGE__->fields());

 sub fields { return qw(...); }

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 fields

  my @aFields = $oSelf->fields();
  my @aFields = __PACKAGE__->fields();

=head2 primary_key - usually the first element of fields();

  my $sPrimaryKey = $oSelf->fields();

=head2 table - database table name this class represents

  my $sTableName = $oSelf->table();

=head2 init - post-constructor hook, called by new();

=head2 new - Constructor

  my $oInstance = ClearPress::model::subclass->new();

=head2 util - ClearPress::util object

  my $oUtil = ClearPress::model::subclass->util();

  my $oUtil = $oInstance->util();

=head2 get - generic 'get' accessor, derived from Class::Accessor.

 Invokes $self->read() if necessary.

 my $sFieldValue = $oSelf->get($sFieldName);

=head2 gen_getarray - Arrayref of objects of a given type for a given database query

  my $arObjects = $oInstance->gen_getarray('ClearPress::model::subclass',
                                           q(SELECT a,b,c FROM x,y WHERE x.d=? AND y.e=?),
                                           @bind_params);

=head2 gen_getall - Arrayref of all objects of type (ref $self) or a given class

  my $arObjects = $self->gen_getall();
  my $arObjects = $self->gen_getall('ClearPress::otherclass');

=head2 create - Generic INSERT into database

  $oSelf->create();

=head2 read - Generic lazy-load from the database

  $oSelf->load();

=head2 update - Generic UPDATE into database against primary_key

  $oSelf->update();

=head2 delete - Generic delete from database

  $oSelf->delete();

=head2 save - Generic save object to database

  $oSelf->save();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rmp@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 GRL, by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

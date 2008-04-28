#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2007-06-25 09:35:19 +0100 (Mon, 25 Jun 2007) $
# Id:            $Id: model.pm 12 2007-06-25 08:35:19Z zerojinx $
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
use Lingua::EN::Inflect qw(PL);
use POSIX qw(strftime);

our $VERSION = do { my ($r) = q$LastChangedRevision: 12 $ =~ /(\d+)/mx; $r; };

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
  my ($self, $class, $query, @args) = @_;

  if(!ref $self) {
    $self = $self->new();
  }

  my $res = [];
  my $sth;

  eval {
    if($query =~ /\?/mx) {
      $sth = $self->util->dbh->prepare_cached($query, {}, 3); # see perldoc DBI for prepare_cached collision handling

    } else {
      $sth = $self->util->dbh->prepare($query);
    }
    $sth->execute(@args);
  };

  if($EVAL_ERROR) {
    carp $EVAL_ERROR . 'caller = '. caller;
    $query =~ s/\s+/\ /smxg;
    local $LIST_SEPARATOR = q(, );
    carp qq(Query was:\n$query\n\nParams: @args);
    return;
  }

  while(my $ref = $sth->fetchrow_hashref()) {
    $ref->{'util'} = $self->util();
    push @{$res}, $class->new($ref);
  }
  return $res;
}

sub gen_getall {
  my ($self, $class, $cachekey) = @_;
  $class ||= ref $self;

  if(!$cachekey) {
    ($cachekey) = $class =~ /([^:]+)$/mx;
    $cachekey   = PL($cachekey);
  }

  if(!$self->{$cachekey}) {
    my $query = qq(SELECT   @{[join q(, ), $class->fields()]}
                   FROM     @{[$class->table()]}
                   ORDER BY @{[$class->primary_key()]});
    $self->{$cachekey} = $self->gen_getarray($class, $query);
  }

  return $self->{$cachekey};
}

sub gen_getfriends {
  my ($self, $class, $cachekey) = @_;
  $class ||= ref $self;

  if(!$cachekey) {
    ($cachekey) = $class =~ /([^:]+)$/mx;
    $cachekey   = PL($cachekey);
  }

  if(!$self->{$cachekey}) {
    my $link  = $self->primary_key();
    my $query = qq(SELECT   @{[join q(, ), $class->fields()]}
                   FROM     @{[$class->table()]}
                   WHERE    $link=?
                   ORDER BY $link);
    $self->{$cachekey} = $self->gen_getarray($class, $query, $self->$link());
  }

  return $self->{$cachekey};
}

sub gen_getfriends_through {
  my ($self, $class, $through, $cachekey) = @_;
  $class ||= ref $self;

  if(!$cachekey) {
    ($cachekey) = $class =~ /([^:]+)$/mx;
    $cachekey   = PL($cachekey); # . '_friends_through';
  }

  if(!$self->{$cachekey}) {
    my $through_key = $self->primary_key();
#carp qq(through_key = $through_key);
    my $friend_key  = $class->primary_key();
#carp qq(friend_key = $friend_key);
    my $query = qq(SELECT @{[join q(, ), map { "f.$_" } $class->fields()]}
                   FROM   @{[$class->table()]} f,
                          $through            t
                   WHERE  t.$through_key = ?
                   AND    t.$friend_key  = f.$friend_key);
    $self->{$cachekey} = $self->gen_getarray($class, $query, $self->$through_key());
  }

  return $self->{$cachekey};
}

sub gen_getobj {
  my ($self, $class)   = @_;
  $class             ||= ref $self;
  my $pk               = $class->primary_key();
  my ($cachekey)       = $class =~ /([^:]+)$/mx;
  $self->{$cachekey} ||= $class->new({
				      'util' => $self->util(),
				      $pk    => $self->$pk(),
				     });
  return $self->{$cachekey};
}

sub gen_getobj_through {
  my ($self, $class, $through, $cachekey) = @_;
  $class ||= ref $self;

  if(!$cachekey) {
    ($cachekey) = $class =~ /([^:]+)$/mx;
  }

  if(!$self->{$cachekey}) {
    # todo: use $through class to determine $through_key
    #       - but $through class may not always be implemented
    my $through_key = q(id_).$through;
    my $friend_key  = $class->primary_key();
    my $query = qq(SELECT @{[join q(, ), map { "f.$_" } $class->fields()]}
                   FROM   @{[$class->table()]} f,
                          $through            t
                   WHERE  t.$through_key = ?
                   AND    t.$friend_key  = f.$friend_key
                   LIMIT 1); # there should only ever be one of these
    $self->{$cachekey} = $self->gen_getarray($class, $query, $self->$through_key())->[0];
  }

  return $self->{$cachekey};
}

sub belongs_to {
  my ($class, @args) = @_;
  return $class->hasa(@args);
}

sub has_a {
  my ($class, @args) = @_;
  return $class->hasa(@args);
}

sub hasa {
  my ($class, $attr) = @_;
  no strict 'refs'; ## no critic

  if(ref $attr ne 'ARRAY') {
    $attr = [$attr];
  }

  for my $single (@{$attr}) {
    my $pkg = $single;

    if(ref $single eq 'HASH') {
      ($pkg)    = values %{$single};
      ($single) = keys %{$single};
    }

    my $namespace = "${class}::$pkg";
    my $yield     = $class;
    $yield        =~ s/^(.*model::).*$/$1$pkg/mx;

    if (defined &{$namespace}) {
      next;
    }

    *{$namespace} = sub {
      my $self = shift;
      return $self->gen_getobj($yield);
    };
  }

  return;
}

sub has_many {
  my ($class, @args) = @_;
  return $class->hasmany(@args);
}

sub hasmany {
  my ($class, $attr) = @_;
  no strict 'refs'; ## no critic

  if(ref $attr ne 'ARRAY') {
    $attr = [$attr];
  }

  for my $single (@{$attr}) {
    my $pkg = $single;

    if(ref $single eq 'HASH') {
      ($pkg)    = values %{$single};
      ($single) = keys %{$single};
    }

    my $plural    = PL($single);
    my $namespace = "${class}::$plural";
    my $yield     = $class;
    $yield        =~ s/^(.*model::).*$/$1$pkg/mx;

    if (defined &{$namespace}) {
      next;
    }

    *{$namespace} = sub {
      my $self = shift;

      return $self->gen_getfriends($yield, $plural);
    };
  }

  return;
}

sub belongs_to_through {
  my ($class, $attr) = @_;
  no strict 'refs'; ## no critic

  if(ref $attr ne 'ARRAY') {
    $attr = [$attr];
  }

  for my $single (@{$attr}) {
    my $pkg = $single;

    if(ref $single eq 'HASH') {
      ($pkg)    = values %{$single};
      ($single) = keys %{$single};
    }
    $pkg =~ s/\|.*//mx;

    my $through;
    ($single, $through) = split /\|/mx, $single;

    if(!$through) {
      croak qq(Cannot build belongs_to_through for $single);
    }

    my $namespace = "${class}::$pkg";
    my $yield     = $class;
    $yield        =~ s/^(.*model::).*$/$1$pkg/mx;

    if (defined &{$namespace}) {
      next;
    }

    *{$namespace} = sub {
      my $self = shift;
      return $self->gen_getobj_through($yield, $through);
    };
  }

  return;
}

sub has_many_through {
  my ($class, $attr) = @_;
  no strict 'refs'; ## no critic

  if(ref $attr ne 'ARRAY') {
    $attr = [$attr];
  }

  for my $single (@{$attr}) {
    my $pkg = $single;

    if(ref $single eq 'HASH') {
      ($pkg)    = values %{$single};
      ($single) = keys %{$single};
    }
    $pkg =~ s/\|.*//mx;

    my $through;
    ($single, $through) = split /\|/mx, $single;

    if(!$through) {
      croak qq(Cannot build has_many_through for $single);
    }

    my $plural    = PL($single);
    my $namespace = "${class}::$plural";
    my $yield     = $class;
    $yield        =~ s/^(.*model::).*$/$1$pkg/mx;

    if (defined &{$namespace}) {
      next;
    }
#carp qq(ns=$namespace, yield $yield through $through);
    *{$namespace} = sub {
      my $self = shift;

      return $self->gen_getfriends_through($yield, $through, $plural);
    };
  }

  return;
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
  my @args = map { $self->{$_} } $self->fields();
  eval {
    $dbh->do($query, {}, @args);

    #########
    # add 'sequence' support here for Oracle
    #
    my $idref = $dbh->selectall_arrayref('SELECT LAST_INSERT_ID()');
    $self->$pk($idref->[0]->[0]);
  };

  if($EVAL_ERROR) {
    $tr_state and $dbh->rollback();
    carp $query.join q(, ), @args;
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

  my @fields = grep { $_ ne $pk } $self->fields();
  my $query   = qq(UPDATE @{[$self->table()]}
                   SET    @{[join q(, ),
                                  map  { qq($_ = ?) }
                                  @fields]}
                   WHERE  $pk=@{[$self->$pk()]});

  eval {
    $dbh->do($query, {}, map { $self->$_() || q() } @fields);
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

  if($pk && defined $self->{$pk}) {
    return $self->update();
  }

  return $self->create();
}

sub zdate {
  my $self = shift;
  my $date = q();

  if(scalar grep { $_ eq 'date' } $self->fields()) {
    $date = $self->date();
    $date =~ s/\ /T/mx;
    $date .='Z';

  } else {
    $date = strftime q(%Y-%m-%dT%H:%M:%SZ), gmtime;
  }

  return $date;
}

1;
__END__

=head1 NAME

ClearPress::model - a base class for the data-model of the ClearPress MVC family

=head1 VERSION

$LastChangedRevision: 12 $

=head1 SYNOPSIS

 use strict;
 use warning;
 use base qw(ClearPress::model);

 __PACKAGE__->mk_accessors(__PACKAGE__->fields());

 sub fields { return qw(...); }

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 fields

  my @aFields = $oModel->fields();
  my @aFields = __PACKAGE__->fields();

=head2 primary_key - usually the first element of fields();

  my $sPrimaryKey = $oModel->fields();

=head2 table - database table name this class represents

  my $sTableName = $oModel->table();

=head2 init - post-constructor hook, called by new();

=head2 new - Constructor

  my $oInstance = ClearPress::model::subclass->new();

=head2 util - ClearPress::util object

  my $oUtil = ClearPress::model::subclass->util();

  my $oUtil = $oInstance->util();

=head2 get - generic 'get' accessor, derived from Class::Accessor.

 Invokes $self->read() if necessary.

 my $sFieldValue = $oModel->get($sFieldName);

=head2 gen_getarray - Arrayref of objects of a given type for a given database query

  my $arObjects = $oModel->gen_getarray('ClearPress::model::subclass',
                                        q(SELECT a,b,c FROM x,y WHERE x.d=? AND y.e=?),
                                        @bind_params);

=head2 gen_getall - Arrayref of all objects of type (ref $self) or a given class

  my $arObjects = $oModel->gen_getall();
  my $arObjects = $oModel->gen_getall('ClearPress::otherclass');

=head2 gen_getobj - An object of a given class based on the value of
the primary key in that class equalling the value in the same
field-name in this object.

  my $oObj = $self->gen_getobj($sClass);

=head2 gen_getfriends - arrayref of relatives related by this model's primary key

  my $arObjects = $oModel->gen_getfriends($sClass);
  my $arObjects = $oModel->gen_getfriends($sClass, $sCacheKey);

=head2 gen_getfriends_through - arrayref of relatives related by this model's primary key through an additional join table

  my $arObjects = $oModel->gen_getfriends($sClass, $sJoinTable);
  my $arObjects = $oModel->gen_getfriends($sClass, $sJoinTable, $sCacheKey);

=head2 gen_getobj_through - fetch a relative through a join table

  my $oRelative = $oModel->gen_getobj_through($sClass, $sJoinTable);
  my $oRelative = $oModel->gen_getobj_through($sClass, $sJoinTable, $sCacheKey);

=head2 hasa - one:one package relationship

  __PACKAGE__->hasa('my::pkg');
  __PACKAGE__->hasa(['my::pkg1', 'my::pkg2']);
  __PACKAGE__->hasa({method => 'my::fieldpkg'});
  __PACKAGE__->hasa([{method_one => 'my::pkg1'},
                     {method_two => 'my::pkg2'});

=head2 hasmany - one:many package relationship

  __PACKAGE__->hasmany('my::pkg');

 If my::pkg has a table of "package" then this creates a method "sub
 packages" in $self, yielding an arrayref of my::pkg objects related
 by the primary_key of $self.

  __PACKAGE__->hasmany(['my::pkg1', 'my::pkg2']);

 Define multiple relationships together.


  __PACKAGE__->hasmany({method => 'my::fieldpkg'});

 Defines a method "sub methods" in $self yielding an arrayref of
 my::fieldpkg objects related by the primary_key of $self.

  __PACKAGE__->hasmany([{method_one => 'my::pkg1'},
                        {method_two => 'my::pkg2'});

 Defines multiple relationships with overridden method names.

=head2 has_a - synonym for hasa()

=head2 belongs_to - synonym for hasa()

=head2 has_many - synonym for hasmany()

=head2 has_many_through - arrayref of related entities through a join table

  Define a 'users' method in this class which fetches users like so:

    SELECT u.id_user, u.foo, u.bar
    FROM   user f, centre_user t
    WHERE  t.id_this = ?           # the primary_key for $self's class
    AND    t.id_user = f.id_user   # the primary_key for friend 'user'

  __PACKAGE__->has_many_through(['user|centre_user']);

=head2 belongs_to_through - a one-to-one relationship, like belongs_to, but through a join table

  __PACKAGE__->belongs_to_through(['user|friend', 'user|enemy']);

=head2 create - Generic INSERT into database

  $oModel->create();

=head2 read - Generic lazy-load from the database

  $oModel->load();

=head2 update - Generic UPDATE into database against primary_key

  $oModel->update();

=head2 delete - Generic delete from database

  $oModel->delete();

=head2 save - Generic save object to database

  $oModel->save();

=head2 zdate - Generic Zulu-date based on object's date() method or gmtime

  my $sZuluTime = $oModel->zdate();

=head2 as_json - JSON representation of this object

  my $sJSON = $oModel->as_json();

=head2 as_xml - XML representation of this object

  my $oXML = $oModel->as_xml();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

Class::Accessor
ClearPress::util
English
Carp

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

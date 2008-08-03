#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2008-07-04 13:52:40 +0100 (Fri, 04 Jul 2008) $
# Id:            $Id: model.pm 177 2008-07-04 12:52:40Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/model.pm,v $
# $HeadURL$
#
package ClearPress::driver;
use strict;
use warnings;
use Carp;
use ClearPress::driver::mysql;
use ClearPress::driver::SQLite;
use DBI;
use English qw(-no_match_vars);
use Carp;
use base qw(Class::Singleton);

our $VERSION = do { my ($r) = q$LastChangedRevision: 177 $ =~ /(\d+)/mx; $r; };

sub new {
  my ($class, @args) = @_;
  return $class->instance(@args);
}

sub _new_instance {
  my ($class, $ref) = @_;
  $ref ||= {};
  bless $ref, $class;
  return $ref;
}

sub dbh {
  my $self = shift;
  carp q[dbh unimplemented];
  return;
}

sub new_driver {
  my ($self, $drivername, $ref) = @_;

  my $drvpkg = "ClearPress::driver::$drivername";
  return $drvpkg->new({
		       drivername => $drivername,
		       %{$ref},
		      });
}

sub DESTROY {
  my $self = shift;

  if($self->{dbh} && $self->{dbh}->ping()) {
    #########
    # flush down any uncommitted transactions & locks
    #
    $self->{dbh}->rollback();
    $self->{dbh}->disconnect();
  }

  return 1;
}

sub create_table {
  my ($self, $t_name, $ref, $t_attrs) = @_;
  my $dbh    = $self->dbh();
  $t_attrs ||= {};
  $ref     ||= {};

  my %values = reverse %{$ref};
  my $pk     = $values{'primary key'};

  if(!$pk) {
    croak qq[Could not determine primary key for table $t_name];
  }

  my @fields = (qq[$pk @{[$self->type_map('primary key')]}]);

  for my $f (grep { $_ ne $pk } keys %{$ref}) {
    push @fields, qq[$f @{[$self->type_map($ref->{$f})]}];
  }

  my $desc  = join q[, ], @fields;
  my $attrs = join q[ ], map { "$_=$t_attrs->{$_}" } keys %{$t_attrs};

  $dbh->do(qq[CREATE TABLE $t_name($desc) $attrs]);
  $dbh->commit();

  return 1;
}

sub drop_table {
  my ($self, $table_name) = @_;
  my $dbh = $self->dbh();

  $dbh->do(qq[DROP TABLE $table_name]);
  $dbh->commit();

  return 1;
}

sub types {
  return {};
}

sub type_map {
  my ($self, $type) = @_;
  if(!defined $type) {
    return;
  }
  return $self->types->{$type} || $type;
}

sub create {
  return;
}

1;
__END__

=head1 NAME

ClearPress::driver

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head2 new_driver

=head2 dbh

=head2 create_table

=head2 drop_table

=head2 create

=head2 type_map - access to a value in the type map, given a key

=head2 types - the whole type map

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Carp

=item Class::Singleton

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.

=cut

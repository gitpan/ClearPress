#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2008-07-04 13:52:40 +0100 (Fri, 04 Jul 2008) $
# Id:            $Id: model.pm 177 2008-07-04 12:52:40Z zerojinx $
# Source:        $Source$
# $HeadURL$
#
package ClearPress::driver::mysql;
use strict;
use warnings;
use base qw(ClearPress::driver);
use English qw(-no_match_vars);
use Carp;
use Readonly;

our $VERSION = do { my ($r) = q$LastChangedRevision: 177 $ =~ /(\d+)/mx; $r; };

Readonly::Scalar our $TYPES => {
				'primary key' => 'bigint unsigned not null auto_increment primary key',
			       };
sub dbh {
  my $self = shift;

  if(!$self->{dbh} ||
     !$self->{dbh}->ping()) {
    my $dsn = sprintf q(DBI:mysql:database=%s;host=%s;port=%s),
		      $self->{dbname} || q[],
		      $self->{dbhost} || q[localhost],
		      $self->{dbport} || q[3306];

    eval {
      $self->{dbh} = DBI->connect($dsn,
				  $self->{dbuser} || q[],
				  $self->{dbpass},
				  {RaiseError => 1,
				   AutoCommit => 0});

    } or do {
      croak qq[Failed to connect to $dsn using @{[$self->{dbuser}||q['']]}\n$EVAL_ERROR];
    };

    #########
    # rollback any junk left behind if this is a cached handle
    #
    $self->{dbh}->rollback();
  }

  return $self->{dbh};
}

sub create {
  my ($self, $query, @args) = @_;
  my $dbh = $self->dbh();

  $dbh->do($query, {}, @args);
  my $idref = $dbh->selectall_arrayref('SELECT LAST_INSERT_ID()');

  return $idref->[0]->[0];
}

sub create_table {
  my ($self, $table_name, $ref) = @_;
  return $self->SUPER::create_table($table_name, $ref, { engine=>'InnoDB'});
}

sub types {
  return $TYPES;
}

1;
__END__

=head1 NAME

ClearPress::driver::mysql

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 dbh - fetch a connected database handle

  my $oDBH = $oDriver->dbh();

=head2 create - run a create query and return this objects primary key

  my $iAssignedId = $oDriver->create($query)

=head2 create_table - mysql-specific create_table

=head2 types - the whole type map

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item ClearPress::driver

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

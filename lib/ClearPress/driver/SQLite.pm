#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2008-07-04 13:52:40 +0100 (Fri, 04 Jul 2008) $
# Id:            $Id: model.pm 177 2008-07-04 12:52:40Z zerojinx $
# Source:        $Source$
# $HeadURL$
#
package ClearPress::driver::SQLite;
use strict;
use warnings;
use base qw(ClearPress::driver);
use Carp;
use English qw(-no_match_vars);
use Readonly;

our $VERSION = do { my ($r) = q$LastChangedRevision: 177 $ =~ /(\d+)/mx; $r; };

Readonly::Scalar our $TYPES => {
				'primary key' => 'INTEGER PRIMARY KEY AUTOINCREMENT',
			       };
sub dbh {
  my $self = shift;

  if(!$self->{dbh}) {
    my $dsn = sprintf q(DBI:SQLite:dbname=%s),
		      $self->{dbname}     || q[];

    eval {
      $self->{dbh} = DBI->connect($dsn, q[], q[],
				  {RaiseError => 1,
				   AutoCommit => 0});
    } or do {
      croak qq[Failed to connect to $dsn:\n$EVAL_ERROR];
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

  my ($table)  = $query =~ /INTO\s+([a-z\d_]+)/mix;
  my $sequence = q[SELECT seq FROM sqlite_sequence WHERE name=?];
  my $idref    = $dbh->selectall_arrayref($sequence, {}, $table);

  return $idref->[0]->[0];
}

sub types {
  return $TYPES;
}

1;
__END__

=head1 NAME

ClearPress::driver::SQLite

=head1 VERSION

$LastChangedRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 create

=head2 dbh

=head2 create_table

=head2 drop_table

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

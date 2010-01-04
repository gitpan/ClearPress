#########
# Author:        rmp
# Last Modified: $Date: 2010-01-04 13:02:42 +0000 (Mon, 04 Jan 2010) $
# Id:            $Id: authenticator.pm 348 2010-01-04 13:02:42Z zerojinx $
# Source:        $Source$
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/lib/ClearPress/authenticator.pm $
#
package ClearPress::authenticator;
use strict;
use warnings;

our $VERSION = do { my ($r) = q$Revision: 348 $ =~ /(\d+)/smx; $r; };

sub new {
  my ($class, $ref) = @_;

  if(!$ref) {
    $ref = {};
  }

  bless $ref, $class;

  return $ref;
}

1;
__END__

=head1 NAME

ClearPress::authenticator

=head1 VERSION

$LastChangedRevision: 348 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

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

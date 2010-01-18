#########
# Author:        rmp
# Last Modified: $Date: 2010-01-18 11:26:22 +0000 (Mon, 18 Jan 2010) $
# Id:            $Id: authenticator.pm 352 2010-01-18 11:26:22Z zerojinx $
# Source:        $Source$
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/lib/ClearPress/authenticator.pm $
#
package ClearPress::authenticator;
use strict;
use warnings;
use Carp;
use English qw(-no_match_vars);

our $VERSION = do { my ($r) = q$Revision: 352 $ =~ /(\d+)/smx; $r; };

sub new {
  my ($class, $ref) = @_;

  if(!$ref) {
    $ref = {};
  }

  bless $ref, $class;

  return $ref;
}

sub _dyn_use {
  my( $self, $classname ) = @_;
  my( $parent_namespace, $module ) = $classname =~ /^(.*?)([^:]+)$/smx ? ($1, $2) : (q[::], $classname);

#  {
#    no strict 'refs'; ## no critic (ProhibitNoStrict)
#    if($parent_namespace->{$module.q[::]}) {
#carp qq[$classname already loaded (${module}:: in $parent_namespace)];
#      return 1;
#    }
#  }

  eval "require $classname" or do { croak $EVAL_ERROR };  ## no critic qw(ProhibitStringyEval)
  $classname->import();

  return 1;
}

1;
__END__

=head1 NAME

ClearPress::authenticator

=head1 VERSION

$Revision: 352 $

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

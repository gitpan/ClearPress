#########
# Author:        rmp
# Last Modified: $Date: 2010-01-04 13:02:42 +0000 (Mon, 04 Jan 2010) $
# Id:            $Id: passwd.pm 348 2010-01-04 13:02:42Z zerojinx $
# Source:        $Source$
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/lib/ClearPress/authenticator/passwd.pm $
#
package ClearPress::authenticator::passwd;
use strict;
use warnings;
use base qw(ClearPress::authenticator);
use Carp;

our $VERSION = do { my ($r) = q$Revision: 348 $ =~ /(\d+)/smx; $r; };

sub authen_credentials {
  my ($self, $ref) = @_;

  if(!$ref ||
     !$ref->{username} ||
     !$ref->{password} ) {
    return;
  }

  my ($name, $passwd) = getpwnam $ref->{username};
  if(!$name) {
    return;
  }

  if((crypt $ref->{password}, $passwd) eq $passwd) {
    return $ref;
  }

  return;
}

1;
__END__

=head1 NAME

ClearPress::authenticator::passwd

=head1 VERSION

$LastChangedRevision: 348 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 authen_credentials - attempt to authenticate against passwd/NIS using given username & password

  my $hrAuthenticated = $oPasswd->authen_credentials({username => $sUsername, password => $sPassword});

  returns undef or hashref

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item ClearPress::authenticator

=item Readonly

=item Carp

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

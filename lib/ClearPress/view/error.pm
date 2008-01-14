#########
# Author:        rmp
# Maintainer:    $Author: rmp $
# Created:       2007-03-28
# Last Modified: $Date: 2007-06-26 15:25:06 +0100 (Tue, 26 Jun 2007) $
# Id:            $Id: error.pm 113 2007-06-26 14:25:06Z rmp $
# $HeadURL: svn+ssh://svn.internal.sanger.ac.uk/repos/svn/new-pipeline-dev/npg-tracking/branches/prerelease-2.0/lib/npg/view/error.pm $
#
package ClearPress::view::error;
use strict;
use warnings;
use base qw(ClearPress::view);
use English qw(-no_match_vars);
use Template;

our $VERSION = do { my ($r) = q$LastChangedRevision: 113 $ =~ /(\d+)/mx; $r; };

sub errstr {
  my $self = shift;
  return $self->_accessor('errstr', @_);
}

sub render {
  my $self   = shift;
  my $errstr = q(Error: ) . $self->errstr();

  if(Template->error()) {
    $errstr .= q(Template Error: ) . Template->error();
  }

  if($EVAL_ERROR) {
    $errstr .= q(Eval Error: ) . $EVAL_ERROR;
  }

  $errstr    =~ s|\S+(npg.*?)$|$1|smgx;
  return q(<div id="main"><h2>An Error Occurred</h2>) .  $self->actions() . q(<p>) . $errstr . q(</p></div>);
}

1;

__END__

=head1 NAME

ClearPress::view::error - specialised view for error handling

=head1 VERSION

$LastChangedRevision: 113 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 errstr - Get/set accessor for an error string to display

  $oErrorView->errstr($sErrorMessage);
  my $sErrorMessage = $oErrorView->errstr();

=head2 render - encapsulated HTML rather than a template, in case the template has caused the error

  my $sErrorOutput = $oErrorView->render();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

ClearPress::view

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

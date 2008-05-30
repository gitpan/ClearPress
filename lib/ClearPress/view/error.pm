#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-03-28
# Last Modified: $Date: 2008-05-31 00:08:14 +0100 (Sat, 31 May 2008) $
# Id:            $Id: error.pm 161 2008-05-30 23:08:14Z zerojinx $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/lib/ClearPress/view/error.pm $
#
package ClearPress::view::error;
use strict;
use warnings;
use base qw(ClearPress::view Class::Accessor);
use English qw(-no_match_vars);
use Template;
use Carp;

__PACKAGE__->mk_accessors(qw(errstr));

our $VERSION = do { my ($r) = q$LastChangedRevision: 161 $ =~ /(\d+)/mx; $r; };

sub render {
  my $self   = shift;
  my $aspect = $self->aspect();
  my $errstr = q(Error: ) . $self->errstr();

  if(Template->error()) {
    $errstr .= q(Template Error: ) . Template->error();
  }

#  if($EVAL_ERROR) {
#    $errstr .= q(Eval Error: ) . $EVAL_ERROR;
#  }
  carp "Serving error: $errstr";
  $errstr =~ s/\ at\ \S+\ line\ \d+//smxg;

  if($aspect =~ /(ajax|xml|rss|atom)$/mx) {
    return qq[<error>$errstr</error>];
  }

  if($aspect =~ /json$/mx) {
    return qq[{error:"$errstr"}];
  }

  if($aspect =~ /xml$/mx) {
    return qq[<span class="error">$errstr</span>];
  }

  return q(<div id="main"><h2>An Error Occurred</h2>) .  $self->actions() . q(<p>) . $errstr . q(</p></div>);
}

1;

__END__

=head1 NAME

ClearPress::view::error - specialised view for error handling

=head1 VERSION

$LastChangedRevision: 161 $

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

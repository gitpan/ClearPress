#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-03-28
# Last Modified: $Date: 2008-12-11 10:54:59 +0000 (Thu, 11 Dec 2008) $
# Id:            $Id: xml_entity.pm 293 2008-12-11 10:54:59Z zerojinx $
# Source:        $Source$
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/branches/prerelease-1.21/lib/ClearPress/Template/Plugin/xml_entity.pm $
package ClearPress::Template::Plugin::xml_entity;
use strict;
use warnings;
use base qw(Template::Plugin::Filter);
use HTML::Entities qw(encode_entities_numeric);

our $VERSION = do { my ($r) = q$LastChangedRevision: 293 $ =~ /(\d+)/smx; $r; };

sub init {
  my $self = shift;
  $self->install_filter('xml_entity');
  return $self;
}

sub filter {
  my ($self, $string) = @_;

  return encode_entities_numeric($string);
}

1;

__END__

=head1 NAME

ClearPress::Template::Plugin::xml_entity - escape double-quotes, newlines and carriage-returns for javascript purposes

=head1 VERSION

$LastChangedRevision: 293 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 init - install filter in TT as 'xml_entity'

=head2 filter - escape double-quotes and newlines

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item Template::Plugin::Filter

=item HTML::Entities

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

$Author: Roger Pettett$

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.10 or,
at your option, any later version of Perl 5 you may have available.

=cut

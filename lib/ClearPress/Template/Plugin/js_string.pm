#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-03-28
# Last Modified: $Date: 2008-11-10 17:15:31 +0000 (Mon, 10 Nov 2008) $
# Id:            $Id: js_string.pm 277 2008-11-10 17:15:31Z zerojinx $
# Source:        $Source$
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/branches/prerelease-1.19/lib/ClearPress/Template/Plugin/js_string.pm $
package ClearPress::Template::Plugin::js_string;
use strict;
use warnings;
use base qw(Template::Plugin::Filter);

our $VERSION = do { my ($r) = q$LastChangedRevision: 277 $ =~ /(\d+)/smx; $r; };

sub init {
  my $self = shift;
  $self->install_filter('js_string');
  return $self;
}

sub filter {
  my ($self, $string) = @_;

  $string =~ s/\r/\\r/smxg;
  $string =~ s/\n/\\n/smxg;
  $string =~ s/"/\\"/smxg;

  return $string;
}

1;

__END__

=head1 NAME

ClearPress::Template::Plugin::js_string - escape double-quotes, newlines and carriage-returns for javascript purposes

=head1 VERSION

$LastChangedRevision: 277 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 init - install filter in TT as 'js_string'

=head2 filter - escape double-quotes and newlines

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item base

=item Template::Plugin::Filter

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

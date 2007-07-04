#########
# Author:        rmp
# Last Modified: $Date: 2007-06-25 09:35:19 +0100 (Mon, 25 Jun 2007) $ $Author: zerojinx $
# Id:            $Id: ClearPress.pm 12 2007-06-25 08:35:19Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress.pm,v $
# $HeadURL$
#
package ClearPress;
use strict;
use warnings;
use ClearPress::model;
use ClearPress::view;
use ClearPress::controller;
use ClearPress::util;

our $VERSION = do { my ($r) = q$LastChangedRevision: 12 $ =~ /(\d+)/mx; $r; };

1;
__END__

=head1 NAME

ClearPress - simple, fresh & fruity MVC framework

=head1 VERSION

$LastChangedRevision: 12 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head2 Application Structure

 /cgi-(bin|perl)/application
 /lib/application/model/*.pm
 /lib/application/view/*.pm
 /data/config.ini
 /data/templates/*.tt2

=head2 Application Setup

 The simplest method for setting up a clearpress application is to use
 the 'clearpress' script in the scripts/ subdirectory. See the POD
 there for usage instructions.

=head1 SUBROUTINES/METHODS

 There are no methods in this module. It's purely for documentation
 purposes. See the POD for this module's dependencies for details of
 the guts.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

ClearPress::model
ClearPress::view
ClearPress::controller
ClearPress::util

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

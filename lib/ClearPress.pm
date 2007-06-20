#########
# Author:        rmp
# Last Modified: $Date: 2007-06-20 23:06:30 +0100 (Wed, 20 Jun 2007) $ $Author: zerojinx $
# Id:            $Id: ClearPress.pm 4 2007-06-20 22:06:30Z zerojinx $
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

our $VERSION = do { my @r = (q$Revision: 1.1.1.1 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

1;
__END__

=head1 NAME

ClearPress - simple, fresh & fruity MVC framework

=head1 VERSION

$LastChangeRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rmp@sanger.ac.ukE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 GRL, by Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

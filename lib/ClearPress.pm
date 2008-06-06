#########
# Author:        rmp
# Last Modified: $Date: 2008-05-31 00:08:14 +0100 (Sat, 31 May 2008) $ $Author: zerojinx $
# Id:            $Id: ClearPress.pm 161 2008-05-30 23:08:14Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress.pm,v $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/lib/ClearPress.pm $
#
package ClearPress;
use strict;
use warnings;
use ClearPress::model;
use ClearPress::view;
use ClearPress::controller;
use ClearPress::util;

our $VERSION = do { my ($r) = q$Revision: 164 $ =~ /(\d+)/mx; $r; };

1;
__END__

=head1 NAME

ClearPress - Simple, fresh & fruity MVC framework

=head1 VERSION

$LastChangedRevision: 161 $

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

strict
warnings
CGI
POSIX
Template
Lingua::EN::Inflect
HTTP::Server::Simple::CGI
Config::IniFiles

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

ClearPress is not an implementation of the classic MVC pattern, in
particular ClearPress views are more like classic MVC controllers, so
if you're expecting that, you may be disappointed. Having said that it
has been used extremely effectively in rapid development of a number
of production applications.

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-06-07
# Last Modified: $Date: 2007/06/14 14:34:36 $
# Id:            $Id: decorator.pm,v 1.1.1.1 2007/06/14 14:34:36 zerojinx Exp $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/decorator.pm,v $
# $HeadURL: svn+ssh://cvs.internal.sanger.ac.uk/repos/svn/new-pipeline-dev/ClearPress-tracking/lib/ClearPress/controller.pm $
#
package ClearPress::decorator;
use strict;
use warnings;
use CGI qw(param);
use base qw(Class::Accessor);

our $VERSION        = do { my ($r) = q$LastChangedRevision: 67 $ =~ /(\d+)/mx; $r; };

__PACKAGE__->mk_accessors(qw(title stylesheet style jsfile script));

sub new {
  my ($class, $ref) = @_;
  $ref ||= {
	    'title' => 'ClearPress',
	   };
  bless $ref, $class;
  return $ref;
}

sub header {
  my $self = shift;
  print qq(Content-type: text/html

<html>
  <head>
    <title>@{[$self->title()]}</title>
  </head>
  <body>);
  return;
}

sub footer {
  print q(  </body>
</html>);
  return;
}

sub username {
  return q();
}

sub cgi {
  my ($self, $cgi) = @_;

  if($cgi) {
    $self->{'cgi'} = $cgi;

  } elsif(!$self->{'cgi'}) {
    $self->{'cgi'} = CGI->new();
  }

  return $self->{'cgi'};
}

sub save_session {
  return;
}

1;
__END__

=head1 NAME

ClearPress::decorator - HTML site-wide header & footer handling

=head1 VERSION

$LastChangeRevision$

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head2 header

=head2 footer

=head2 username

=head2 cgi

=head2 save_session

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

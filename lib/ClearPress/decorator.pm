#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-06-07
# Last Modified: $Date: 2008-10-31 13:36:08 +0000 (Fri, 31 Oct 2008) $
# Id:            $Id: decorator.pm 265 2008-10-31 13:36:08Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/decorator.pm,v $
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/branches/prerelease-1.18/lib/ClearPress/decorator.pm $
#
package ClearPress::decorator;
use strict;
use warnings;
use CGI qw(param);
use base qw(Class::Accessor);

our $VERSION  = do { my ($r) = q$LastChangedRevision: 265 $ =~ /(\d+)/mx; $r; };
our $DEFAULTS = {
		 'meta_content_type' => 'text/html',
		 'meta_version'      => '0.1',
		 'meta_description'  => q(),
		 'meta_author'       => q$Author: zerojinx $,
		 'meta_keywords'     => q(clearpress),
		};

our $ARRAY_FIELDS = {
		     'jsfile'     => 1,
		     'rss'        => 1,
		     'atom'       => 1,
		     'stylesheet' => 1,
		     'script'     => 1,
		    };
__PACKAGE__->mk_accessors(__PACKAGE__->fields());

sub fields {
  return qw(title stylesheet style jsfile script atom rss
            meta_keywords meta_description meta_author meta_version
            meta_refresh meta_cookie meta_content_type meta_expires
            onload onunload onresize)
}

sub get {
  my ($self, $field) = @_;

  if($ARRAY_FIELDS->{$field}) {
    return @{$self->{$field} || $DEFAULTS->{$field} || []};

  } else {
    return $self->{$field} || $DEFAULTS->{$field};
  }
}

sub defaults {
  my ($self, $key) = @_;
  return $DEFAULTS->{$key};
}

sub new {
  my ($class, $ref) = @_;
  $ref ||= {
	    'title' => 'ClearPress',
	   };
  bless $ref, $class;
  return $ref;
}

sub header {
  my ($self) = @_;

  return $self->http_header() . $self->site_header();
}

sub cookie {
  my ($self, @cookies) = @_;

  if(scalar @cookies) {
    $self->{'cookie'} = \@cookies;
  }

  return @{$self->{'cookie'}||[]};
}

sub http_header {
  my $self    = shift;
  my @cookies = grep { $_ } ($self->cookie());
  my @headers = (q(Content-type: text/html; charset=iso8859-1),
                 map {
                   "Set-Cookie: $_";
                 } @cookies);
  return join "\n", @headers, "\n";
}

sub site_header {
  my ($self) = @_;
  my $cgi    = $self->cgi();

  my $ss = qq(@{[map {
    qq(    <link rel="stylesheet" type="text/css" href="$_" />);
  } grep { $_ } $self->stylesheet()]});

  if($self->style()) {
    $ss .= q(<style type="text/css">). $self->style() .q(</style>);
  }

  my $rss = qq(@{[map {
    qq(    <link rel="alternate" type="application/rss+xml" title="RSS" href="$_" />\n);
  } grep { $_ } $self->rss()]});

  my $atom = qq(@{[map {
    qq(    <link rel="alternate" type="application/atom+xml" title="ATOM" href="$_" />\n);
  } grep { $_ } $self->atom()]});

  my $js = qq(@{[map {
    qq(    <script type="text/javascript" src="@{[$cgi->escapeHTML($_)]}"></script>\n);
  } grep { $_ } $self->jsfile()]});

  my $script = qq(@{[map {
    qq(    <script type="text/javascript">$_</script>\n);
  } grep { $_ } $self->script()]});

  my $onload   = (scalar $self->onload())   ? qq( onload="@{[  join q(;), $self->onload()]}")   : q();
  my $onunload = (scalar $self->onunload()) ? qq( onunload="@{[join q(;), $self->onunload()]}") : q();
  my $onresize = (scalar $self->onresize()) ? qq( onresize="@{[join q(;), $self->onresize()]}") : q();
  return qq(<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN" "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en-gb">
  <head>
    <meta http-equiv="Content-Type" content="@{[$self->meta_content_type() || $self->defaults('meta_content_type')]}" />
@{[(scalar $self->meta_cookie())?(map { qq( <meta http-equiv="Set-Cookie" content="$_" />\n) } $self->meta_cookie()):q()]}@{[$self->meta_refresh()?qq(<meta http-equiv="Refresh" content="@{[$self->meta_refresh()]}" />):q()]}@{[$self->meta_expires()?qq(<meta http-equiv="Expires" content="@{[$self->meta_expires()]}" />):q()]}    <meta name="author"      content="@{[$self->meta_author()      || $self->defaults('meta_author')]}" />
    <meta name="version"     content="@{[$self->meta_version()     || $self->defaults('meta_version')]}" />
    <meta name="description" content="@{[$self->meta_description() || $self->defaults('meta_description')]}" />
    <meta name="keywords"    content="@{[$self->meta_keywords()    || $self->defaults('meta_keywords')]}" />
    <title>@{[$self->title()]}</title>
$ss$rss$atom$js$script  </head>
  <body$onload$onunload$onresize>\n);
}

sub footer {
  return q(  </body>
</html>);
}

sub username {
  return q();
}

sub cgi {
  my ($self, $cgi) = @_;

  if($cgi) {
    $self->{cgi} = $cgi;

  } elsif(!$self->{cgi}) {
    $self->{cgi} = CGI->new();
  }

  return $self->{cgi};
}

sub session {
  return {};
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

=head2 defaults - Accessor for default settings used in HTML headers

  my $sValue = $oDecorator->defaults($sKey);

=head2 fields - All generic get/set accessors for this object

  my @aFields = $oDecorator->fields();

=head2 cookie - Get/set cookies

  $oDecorator->cookie(@aCookies);
  my @aCookies = $oDecorator->cookie();

=head2 header - construction of HTTP and HTML site headers

=head2 http_header - construction of HTTP response headers

e.g. content-type, set-cookie etc.

  my $sHTTPHeaders = $oDecorator->http_header();

=head2 site_header - construction of HTML site headers

i.e. <html>...<body>

  Subclass and extend this method to provide consistent site-branding

  my $sHTMLHeader = $oDecorator->site_header();

=head2 footer - pass-through to site_footer

=head2 site_footer - construction of HTML site footers

i.e. </body></html> by default

  my $sHTMLFooter = $oDecorator->site_footer

=head2 username - username of authenticated user

  my $sUsername = $oDecorator->username();

=head2 cgi - get/set accessor for a CGI object

  $oDecorator->cgi($oCGI);

  my $oCGI = $oDecorator->cgi();

=head2 session - Placeholder for a session hashref

  my $hrSession = $oUtil->session();

 This will not do any session handling until subclassed and overridden for a specific environment/service.

=head2 save_session - Placeholder for session saving

 This will not do any session handling until subclassed and overridden for a specific environment/service.

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item CGI

=item base

=item Class::Accessor

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut

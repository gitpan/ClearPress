#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2007/06/14 14:42:42 $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/util.pm,v $
# Id:            $Id: util.pm,v 1.2 2007/06/14 14:42:42 zerojinx Exp $
# $HeadURL$
#
package ClearPress::util;
use strict;
use warnings;
use DBI;
use Config::IniFiles;
use Carp;

our $VERSION   = do { my ($r) = q$LastChangedRevision: 67 $ =~ /(\d+)/mx; $r; };

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};

  if(!exists $ref->{'transactions'}) {
    $ref->{'transactions'} = 1;
  }

  my $self = bless $ref, $class;
  return $self;
}

sub data_path {
  return q(.);
}

sub configpath {
  my $self = shift;
 
  if(@_) {
    $self->{'configpath'} = shift;
  }

  return $self->{'configpath'} || $self->data_path().'/config.ini';
}

sub config {
  my $self       = shift;
  my $configpath = $self->configpath() || q();
  my $dtconfigpath;

  if(!$self->{'_config'}) {
    ($dtconfigpath) = $configpath =~ m|([a-z\d_/\.\-]+)|mix;
    $dtconfigpath ||= q();

    if($dtconfigpath ne $configpath) {
      croak qq(Failed to detaint configpath: '$configpath');
    }

    $self->{'_config'} ||= Config::IniFiles->new(
						 -file => $dtconfigpath,
						);
  }

  if(!$self->{'_config'}) {
    croak q(No configuration available);
  }
  return $self->{'_config'};
}

sub dbh {
  my $self    = shift;
  my $config  = $self->config();
  my $section = 'application';

  if(!$section) {
    croak q(Unable to determine config set to use);
  }

  $self->{'dsn'} = sprintf q(DBI:mysql:database=%s;host=%s),
			   $config->val($section, 'dbname') || q(),
			   $config->val($section, 'dbhost') || q();

  $self->{'dbh'} ||= DBI->connect_cached($self->{'dsn'},
					 $config->val($section, 'dbuser') || q(),
					 $config->val($section, 'dbpass') || q(),
					 {RaiseError => 1,
					  AutoCommit => 0});
  return $self->{'dbh'};
}

sub quote {
  my ($self, $str) = @_;
  return $self->dbh->quote($str);
}

sub _accessor {
  my ($self, $field, $val) = @_;
  if(defined $val) {
    $self->{$field} = $val;
  }
  return $self->{$field};
}

sub transactions {
  my $self = shift;
  return $self->_accessor('transactions', @_);
}

sub username {
  my $self = shift;
  return $self->_accessor('username', @_);
}

sub cgi {
  my $self = shift;
  return $self->_accessor('cgi', @_);
}

sub requestor {
  my $self = shift;
  return $self->_accessor('requestor', @_);
}

sub profiler {
  my $self = shift;
  return $self->_accessor('profiler', @_);
}

sub DESTROY {
  my $self = shift;
  $self->{'dbh'} and $self->{'dbh'}->disconnect();
  return;
}

1;

__END__

=head1 NAME

ClearPress::util - A database handle and utility object

=head1 VERSION

$LastChangedRevision: 67 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - Constructor

  my $oUtil = ClearPress::util->new({
                              'configpath' => '/path/to/config.ini', # Optional
                             });

=head2 data_path - Accessor to data directory containing config.ini and template subdir

  my $sPath = $oUtil->data_path();

=head2 configpath - Get/set accessor for path to config file

  $oUtil->configpath('/path/to/configfile/');

  my $sConfigPath = $oUtil->configpath();

=head2 config - The Config::IniFiles object for our configpath

  my $oConfig = $oUtil->config();

=head2 dbh - A database handle for the supported database

  my $oDbh = $oUtil->dbh();

=head2 quote - Shortcut for $oDbh->quote('...');

  my $sQuoted = $oUtil->quote($sUnquoted);

=head2 transactions - Enable/disable transaction commits

 Example: A cascade of object saving

  $util->transactions(0);                       # disable transactions

  for my $subthing (@{$thing->subthings()}) {   # cascade object saves (without commits)
    $subthing->save();
  }

  $util->transactions(1);                       # re-enable transactions
  $thing->save();                               # save parent object (with commit)

=head2 username - Get/set accessor for requestor's username

  $oUtil->username((getpwuid $<)[0]);
  $oUtil->username($sw->username());

  my $sUsername = $oUtil->username();

=head2 cgi - Placeholder for a CGI object (or at least something with the same param() interface)

  $oUtil->cgi($oCGI);
  my $oCGI = $oUtil->cgi();

=head2 profiler - Placeholder for a Website::Utilities::Profiler object

  $oUtil->profiler($oProfiler);
  my $oProf = $oUtil->profiler();

=head2 requestor - a ClearPress::model::user who requested this page (constructed by view.pm)

  This is usually used for testing group membership for authorisation checks

  my $oRequestingUser = $oUtil->requestor();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

DBI, Config::IniFiles

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

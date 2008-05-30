#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2008-05-31 00:08:14 +0100 (Sat, 31 May 2008) $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/util.pm,v $
# Id:            $Id: util.pm 161 2008-05-30 23:08:14Z zerojinx $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/lib/ClearPress/util.pm $
#
package ClearPress::util;
use strict;
use warnings;
use DBI;
use Config::IniFiles;
use Carp;
use POSIX qw(strftime);
use English qw(-no_match_vars);

our $VERSION = do { my ($r) = q$LastChangedRevision: 161 $ =~ /(\d+)/mx; $r; };

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
  return q(data);
}

sub configpath {
  my ($self, @args) = @_;

  if(scalar @args) {
    $self->{'configpath'} = shift;
  }

  return $self->{'configpath'} || $self->data_path().'/config.ini';
}

sub config {
  my $self       = shift;
  my $configpath = $self->configpath() || q();
  my $dtconfigpath;

  if(!$self->{'_config'}) {
    ($dtconfigpath) = $configpath =~ m{([a-z\d_/\.\-]+)}mix;
    $dtconfigpath ||= q();

    if($dtconfigpath ne $configpath) {
      croak qq(Failed to detaint configpath: '$configpath');
    }

    if(!-e $dtconfigpath) {
      croak qq(No such file: $dtconfigpath);
    }

    $self->{'_config'} ||= Config::IniFiles->new(
						 -file => $dtconfigpath,
						);
  }

  if(!$self->{'_config'}) {
    croak qq(No configuration available:\n). join q(, ), @Config::IniFiles::errors; ## no critic
  }

  return $self->{'_config'};
}

sub dbh {
  my $self = shift;

  if(!$self->{'dbh'}) {
    my $config  = $self->config();
    my $section = 'application';

    if(!$section) {
      croak q(Unable to determine config set to use);
    }

    $self->{'dsn'} = sprintf q(DBI:mysql:database=%s;host=%s),
			     $config->val($section, 'dbname') || q(),
			     $config->val($section, 'dbhost') || q();

    $self->{'dbh'} = DBI->connect($self->{'dsn'},
					 $config->val($section, 'dbuser') || q(),
					 $config->val($section, 'dbpass') || q(),
					 {RaiseError => 1,
					  AutoCommit => 0});
    #########
    # rollback any junk left behind if this is a cached handle
    #
    $self->{'dbh'}->rollback();

    #########
    # make our transactions as clean as can be
    #
#    $self->{'dbh'}->do(q(SET TRANSACTION ISOLATION LEVEL SERIALIZABLE));
  }

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
  my ($self, @args) = @_;
  return $self->_accessor('transactions', @args);
}

sub username {
  my ($self, @args) = @_;
  return $self->_accessor('username', @args);
}

sub cgi {
  my ($self, @args) = @_;
  return $self->_accessor('cgi', @args);
}

sub requestor {
  my ($self, @args) = @_;
  return $self->_accessor('requestor', @args);
}

sub profiler {
  my ($self, @args) = @_;
  return $self->_accessor('profiler', @args);
}

sub session {
  my ($self, @args) = @_;
  return $self->_accessor('session', @args);
}

sub DESTROY {
  my $self = shift;
  if($self->{'dbh'}) {
    #########
    # flush down any uncommitted transactions & locks
    #
    $self->{'dbh'}->rollback();
    $self->{'dbh'}->disconnect();
  }
  return;
}

sub log { ## no critic
  my ($self, @args) = @_;
  print {*STDERR} map { (strftime '[%Y-%m-%dT%H:%M:%S] ', localtime). "$_\n" } @args or croak $ERRNO;
  return;
}

1;

__END__

=head1 NAME

ClearPress::util - A database handle and utility object

=head1 VERSION

$LastChangedRevision: 161 $

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

=head2 session - Placeholder for a session hashref

  $oUtil->session($hrSession);
  my $hrSession = $oUtil->session();

=head2 profiler - Placeholder for a Website::Utilities::Profiler object

  $oUtil->profiler($oProfiler);
  my $oProf = $oUtil->profiler();

=head2 requestor - a ClearPress::model::user who requested this page (constructed by view.pm)

  This is usually used for testing group membership for authorisation checks

  my $oRequestingUser = $oUtil->requestor();

=head2 log - Formatted debugging output to STDERR

  $oUtil->log(@aMessages);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

strict
warnings
DBI
Config::IniFiles
Carp
English
POSIX

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

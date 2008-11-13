#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2008-11-10 17:15:31 +0000 (Mon, 10 Nov 2008) $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/util.pm,v $
# Id:            $Id: util.pm 277 2008-11-10 17:15:31Z zerojinx $
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/branches/prerelease-1.19/lib/ClearPress/util.pm $
#
package ClearPress::util;
use strict;
use warnings;
use base qw(Class::Accessor);
use Config::IniFiles;
use Carp;
use POSIX qw(strftime);
use English qw(-no_match_vars);
use ClearPress::driver;
use CGI;

our $VERSION              = do { my ($r) = q$LastChangedRevision: 277 $ =~ /(\d+)/smx; $r; };
our $DEFAULT_TRANSACTIONS = 1;
our $DEFAULT_DRIVER       = 'mysql';

__PACKAGE__->mk_accessors(qw(transactions username requestor profiler session));

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};

  if(!exists $ref->{transactions}) {
    $ref->{transactions} = $DEFAULT_TRANSACTIONS;
  }

  my $self = bless $ref, $class;
  return $self;
}

sub cgi {
  my ($self, $cgi) = @_;

  if($cgi) {
    $self->{cgi} = $cgi;
  }

  if(!$self->{cgi}) {
    $self->{cgi} = CGI->new();
  }

  return $self->{cgi};
}

sub data_path {
  return q(data);
}

sub configpath {
  my ($self, @args) = @_;

  if(scalar @args) {
    $self->{configpath} = shift @args;
  }

  return $self->{configpath} || $self->data_path().'/config.ini';
}

sub dbsection {
  return $ENV{dev} || 'live';
}

sub config {
  my $self       = shift;
  my $configpath = $self->configpath() || q();
  my $dtconfigpath;

  if(!$self->{config}) {
    ($dtconfigpath) = $configpath =~ m{([a-z\d_/\.\-]+)}smix;
    $dtconfigpath ||= q();

    if($dtconfigpath ne $configpath) {
      croak qq(Failed to detaint configpath: '$configpath');
    }

    if(!-e $dtconfigpath) {
      croak qq(No such file: $dtconfigpath);
    }

    $self->{config} ||= Config::IniFiles->new(
					       -file => $dtconfigpath,
					      );
  }

  if(!$self->{config}) {
    croak qq(No configuration available:\n). join q(, ), @Config::IniFiles::errors; ## no critic
  }

  return $self->{config};
}

sub dbh {
  my $self = shift;

  return $self->driver->dbh();
}

sub quote {
  my ($self, $str) = @_;
  return $self->dbh->quote($str);
}

sub _accessor {
  my ($self, $field, $val) = @_;
  carp q[_accessor is deprecated. Use __PACKAGE__->mk_accessors(...) instead];
  if(defined $val) {
    $self->{$field} = $val;
  }
  return $self->{$field};
}

sub driver {
  my ($self, @args) = @_;

  if(!$self->{driver}) {
    my $dbsection = $self->dbsection();
    my $config    = $self->config();

    if(!$dbsection || !$config->SectionExists($dbsection)) {
      croak q[Unable to determine config set to use. Try adding [live] [dev] or [test] sections to config.ini];
    }

    my $drivername = $config->val($dbsection, 'driver') || $DEFAULT_DRIVER;
    my $ref        = {};

    for my $field ($config->Parameters($dbsection)) {
      $ref->{$field} = $config->val($dbsection, $field);
    }

    $self->{driver} = ClearPress::driver->new_driver($drivername, $ref);
  }

  return $self->{driver};
}

sub log { ## no critic
  my ($self, @args) = @_;
  print {*STDERR} map { (strftime '[%Y-%m-%dT%H:%M:%S] ', localtime). "$_\n" } @args or croak $ERRNO;
  return 1;
}

sub cleanup {
}

1;

__END__

=head1 NAME

ClearPress::util - A database handle and utility object

=head1 VERSION

$LastChangedRevision: 277 $

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

=head2 driver - driver name from config.ini

  my $sDriverName = $oUtil->driver();

=head2 dbsection - dev/test/live/application based on $ENV{dev}

  my $sSection = $oUtil->dbsection();

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

=head2 cleanup - housekeeping stub for subclasses - called when response has completed processing

  $oUtil->cleanup();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item DBI

=item Config::IniFiles

=item Carp

=item POSIX

=item English

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

#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-03-28
# Last Modified: $Date: 2007-06-25 09:35:19 +0100 (Mon, 25 Jun 2007) $
# Id:            $Id: view.pm 12 2007-06-25 08:35:19Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/view.pm,v $
# $HeadURL$
#
package ClearPress::view;
use strict;
use warnings;
use Template;
use ClearPress::util;
use Carp;
use English qw(-no_match_vars);

our $VERSION = do { my ($r) = q$LastChangedRevision: 12 $ =~ /(\d+)/mx; $r; };

sub new {
  my ($class, $self)    = @_;
  $self               ||= {};
  $self->{'warnings'} ||= [];
  bless $self, $class;

  my $util                      = $self->util();
  my $username                  = $util->username();
  $self->{'requestor_username'} = $username;
  $self->{'logged_in'}          = $username?1:0;
  my $aspect                    = $self->aspect() || q();
  $self->{'content_type'}     ||= ($aspect =~ /(rss|atom|ajax)$/mx)?'text/xml':'text/html';

  return $self;
}

sub add_warning {
  my ($self, $warning) = @_;
  push @{$self->{'warnings'}}, $warning;
  return;
}

sub authorised {
  my $self   = shift;
  my $action = $self->action();
  my $aspect = $self->aspect();
  my $util   = $self->util();

  if(!$util->requestor()) {
    #########
    # If there's no requestor user object then authorisation isn't supported
    #
    return 1;
  }

  if($action =~ /^list/mx ||
     ($action eq 'read' &&
      $aspect !~ /^add/mx)) {
    #########
    # by default assume public read access for 'read' actions
    #
    return 1;

  } else {
    #########
    # by default allow only 'admin' group for non-read actions (create, update, delete)
    #
    if($util->requestor->is_member_of('admin')) {
      return 1;
    }
  }

  return;
}

sub template_name {
  my $self   = shift;
  my ($name) = (ref $self) =~ /([^:]+)$/mx;
  my $method = $self->method_name();

  if($method) {
    $name .= "_$method";
  }

  return $name;
}

sub method_name {
  my $self   = shift;
  my $aspect = $self->aspect();
  my $action = $self->action();
  my $method = $aspect || $action ;
  my $model  = $self->model();
  my $pk     = $model->primary_key();

  if($method eq 'read' &&
     !$model->$pk()) {
    $method = 'list';
  }

  return $method;
}

sub render {
  my $self   = shift;
  my $util   = $self->util();
  my $aspect = $self->aspect();
  my $action = $self->action();

  if(!$util) {
    croak q(No util object available);
  }

  my $requestor = $util->requestor();

  if(!$self->authorised()) {
    if(!$requestor) {
      croak q(Authorisation unavailable for this view.);
    }
    my $username = $requestor->username();
    if(!$username) {
      croak q(You are not authorised for this view. You need to log in.);
    }
    croak q(You are not authorised for this view);
  }


  #########
  # Figure out and call the appropriate action if available
  #
  my $method = $self->method_name();
  if($method !~ /^(add|edit|create|read|update|delete|list)/mx) {
    croak qq(Illegal method: $method);
  }

  if($self->can($method)) {
    $self->$method();
  } else {
    croak qq(Unsupported method: $method);
  }

  my $model   = $self->model();
  my $actions = my $warnings = q();

  if(!($aspect =~ /(rss|atom|ajax)$/mx)) {
    $actions  = $self->actions();
    $self->tt->process('warnings.tt2', {
					'requestor' => $requestor,
					'view'      => $self,
				       }, \$warnings);
  }
  my $tmpl = $self->template_name();

  for my $copy (qw(logged_in)) {
    $model->{$copy} ||= $self->{$copy};
  }

  my $content = q();
  $self->tt->process("$tmpl.tt2", {
				   'requestor'   => $requestor,
				   'model'       => $model,
				   'SCRIPT_NAME' => $ENV{'SCRIPT_NAME'},
				   'HTTP_HOST'   => $ENV{'HTTP_HOST'},
				  }, \$content) or croak $self->tt->error();
  return $warnings . $actions . $content || q(No data);
}

sub _populate_from_cgi {
  my $self  = shift;
  my $util  = $self->util();
  my $model = $self->model();
  my $cgi   = $util->cgi();

  #########
  # Populate model object with parameters posted into CGI
  # by default (in controller.pm) model will only have util & its primary_key.
  #
  $model->read();
  for my $field ($model->fields()) {
    my $v = $cgi->escapeHTML($cgi->param($field) || q());
    if($v) {
      $model->$field($v);
    }
  }
  return;
}

sub add {
  my $self = shift;
  return $self->_populate_from_cgi();
}

sub edit {
  my $self = shift;
  return $self->_populate_from_cgi();
}

sub list {
}

sub read { ## no critic
}

sub delete { ## no critic
}

sub update {
  my $self  = shift;
  my $util  = $self->util();
  my $model = $self->model();
  my $cgi   = $util->cgi();

  #########
  # Populate model object with parameters posted into CGI
  # by default (in controller.pm) model will only have util & its primary_key.
  #
  $model->read();
  for my $field ($model->fields()) {
    my $v = $cgi->escapeHTML($cgi->param($field) || q());
    if($v) {
      $model->$field($v);
    }
  }

  $model->update() or croak qq(Failed to update entity: $EVAL_ERROR);
  return;
}

sub create {
  my $self  = shift;
  my $util  = $self->util();
  my $model = $self->model();
  my $cgi   = $util->cgi();

  #########
  # Populate model object with parameters posted into CGI
  # by default (in controller.pm) model will only have util & its primary_key.
  #
  $model->read();
  for my $field ($model->fields()) {
    my $v = $cgi->escapeHTML($cgi->param($field) || q());
    if($v) {
      $model->$field($v);
    }
  }

  $model->create() or croak qq(Failed to create entity: $EVAL_ERROR);
  return;
}

sub tt {
  my ($self, $tt) = @_;
  my $util = $self->util();

  if($tt) {
    $util->{'tt'} = $tt;
  }

  if(!$util->{'tt'}) {
    $util->{'tt'} = Template->new({
				   'RECURSION'    => 1,
				   'INCLUDE_PATH' => (sprintf q(%s/templates), $util->data_path()),
				   'EVAL_PERL'    => 1,
				  }) or croak $Template::ERROR;
  }
  return $util->{'tt'};
}

sub _accessor {
  my ($self, $field, $val) = @_;
  if(defined $val) {
    $self->{$field} = $val;
  }
  return $self->{$field};
}

sub util {
  my $self = shift;
  return $self->_accessor('util', @_);
}

sub model {
  my $self = shift;
  return $self->_accessor('model', @_);
}

sub action {
  my $self = shift;
  return $self->_accessor('action', @_);
}

sub aspect {
  my $self = shift;
  return $self->_accessor('aspect', @_);
}

sub content_type {
  my $self = shift;
  return $self->_accessor('content_type', @_);
}

sub decor {
  my $self = shift;
  my $aspect = $self->aspect() || q();

  if($aspect =~ /(rss|atom|ajax)$/mx) {
    return 0;
  }
  return 1;
}

sub actions {
  my $self    = shift;
  my $content = q();
  $self->{'requestor'}   = $self->util->requestor();
  $self->{'SCRIPT_NAME'} = $ENV{'SCRIPT_NAME'};
  $self->{'HTTP_HOST'}   = $ENV{'HTTP_HOST'};
  $self->tt->process('actions.tt2', $self, \$content);
  return $content;
}

1;
__END__

=head1 NAME

ClearPress::view - MVC view superclass

=head1 VERSION

$LastChangedRevision: 12 $

=head1 SYNOPSIS

  my $oView = ClearPress::view::<subclass>->new({'util' => $oUtil});
  $oView->model($oModel);

  print $oView->decor()?
    $oDecorator->header()
    :
    q(Content-type: ).$oView->content_type()."\n\n";

  print $oView->render();

  print $oView->decor()?$oDecorator->footer():q();

=head1 DESCRIPTION

View superclass for the ClearPress framework

=head1 SUBROUTINES/METHODS

=head2 new - constructor

  my $oView = ClearPress::view::<subclass>->new({'util' => $oUtil, ...});

=head2 template_name - the name of the template to load, based on view class and method_name()

  my $sTemplateName = $oView->template_name();

=head2 method_name - the name of the method to invoke on the model, based on action and aspect

  my $sMethodName = $oView->method_name();

=head2 add_warning

  $oView->add_warning($sWarningMessage);

=head2 authorised - Verify authorisation for this view

  This should usually take into account $self->action() which suggests
  read or write access.

  my $bIsAuthorised = $oView->authorised();

=head2 render - generates and returns content for this view

  my $sViewOutput = $oView->render();

=head2 list - stub for entity list actions

=head2 create - A default model creation/save method

  $oView->create();

  Populates $oSelf->model() with its expected parameters from the CGI
  block, then calls $oModel->create();

=head2 add - stub for single-entity-creation actions

=head2 edit - stub for single-entity editing

=head2 read - stub for single-entity-view actions

=head2 update - stub for entity update actions

=head2 delete - stub for entity delete actions

=head2 tt - a configured Template (TT2) object

  my $tt = $oView->tt();

=head2 util - get/set accessor for utility object

  $oView->util($oUtil);
  my $oUtil = $oView->util();

=head2 model - get/set accessor for data model object

  $oView->model($oModel);
  my $oModel = $oView->model();

=head2 action - get/set accessor for the action being performed on this view

  $oView->action($sAction);
  my $sAction = $oView->action();

=head2 aspect - get/set accessor for the aspect being performed on this view

  $oView->aspect($sAction);
  my $sAction = $oView->aspect();

=head2 content_type - get/set accessor for content mime-type (Content-Type HTTP header)

  $oView->content_type($sContentType);
  my $sContentType = $oView->content_type();

=head2 decor - get/set accessor for page decoration toggle

  $oView->decor($bDecorToggle);
  my $bDecorToggle = $oView->decor();

=head2 actions - templated output for available actions

  my $sActionOutput = $oView->actions();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

Template
ClearPress::util
Carp
English

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2007 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

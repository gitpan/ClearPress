#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-03-28
# Last Modified: $Date: 2008-08-02 18:44:15 +0100 (Sat, 02 Aug 2008) $
# Id:            $Id: view.pm 224 2008-08-02 17:44:15Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/view.pm,v $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/lib/ClearPress/view.pm $
#
package ClearPress::view;
use strict;
use warnings;
use base qw(Class::Accessor);
use Template;
use ClearPress::util;
use Carp;
use English qw(-no_match_vars);
use POSIX qw(strftime);
use ClearPress::Template::Plugin::js_string;

our $VERSION = do { my ($r) = q$LastChangedRevision: 224 $ =~ /(\d+)/mx; $r; };
our $DEBUG_OUTPUT = 0;

__PACKAGE__->mk_accessors(qw(util model action aspect content_type entity_name autoescape));

sub new {
  my ($class, $self)    = @_;
  $self               ||= {};
  bless $self, $class;

  my $util                    = $self->util();
  my $username                = $util?$util->username():q[];
  $self->{requestor_username} = $username;
  $self->{logged_in}          = $username?1:0;
  $self->{warnings}           = [];
  $self->{output_buffer}      = [];
  $self->{output_finished}    = 0;
  $self->{autoescape}         = 1;

  my $aspect = $self->aspect() || q();

  $self->{content_type} ||= ($aspect =~ /(rss|atom|ajax|xml)$/mx)?'text/xml':q();
  $self->{content_type} ||= ($aspect =~ /(js|json)$/mx)?'application/javascript':q();
  $self->{content_type} ||= ($aspect =~ /_(png)$/mx)?'image/png':q();
  $self->{content_type} ||= ($aspect =~ /_(jpg)$/mx)?'image/jpeg':q();
  $self->{content_type} ||= 'text/html';

  $self->init();
  return $self;
}

sub init {
  return 1;
}

sub add_warning {
  my ($self, $warning) = @_;
  push @{$self->{warnings}}, $warning;
  return 1;
}

sub warnings {
  my $self = shift;
  return $self->{warnings};
}

sub _accessor {
  my ($self, $field, $val) = @_;
  carp q[_accessor is deprecated. Use __PACKAGE__->mk_accessors(...) instead];
  if(defined $val) {
    $self->{$field} = $val;
  }
  return $self->{$field};
}

sub authorised {
  my $self   = shift;
  my $action = $self->action() || q();
  my $aspect = $self->aspect() || q();
  my $util   = $self->util();

  if(!$util->requestor()) {
    #########
    # If there's no requestor user object then authorisation isn't supported
    #
    return 1;
  }

  if($action =~ /^list/mx ||
     ($action eq 'read' &&
      $aspect !~ /^(add|delete|update|create)/mx)) {
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
  my $name = $self->entity_name();
  if(!$name) {
    ($name) = (ref $self) =~ /view::(.*)$/mx;
  }
  $name    ||= 'view';
  my $method = $self->method_name();

  if($method) {
    $name .= "_$method";
  }
  $name =~ s/:+/_/mxg;

  return $name;
}

sub method_name {
  my $self   = shift;
  my $aspect = $self->aspect();
  my $action = $self->action();
  my $method = $aspect || $action;
  my $model  = $self->model();
  my $pk     = $model->primary_key();

  if($pk               &&
     $method eq 'read' &&
     !$model->$pk()) {
    $method = 'list';
  }

  return $method;
}

sub render {
  my $self   = shift;
  my $util   = $self->util();
  my $aspect = $self->aspect() || q[];
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
    croak qq[You ($username) are not authorised for this view];
  }

  #########
  # Figure out and call the appropriate action if available
  #
  my $method = $self->method_name();
  if($method !~ /^(add|edit|create|read|update|delete|list)/mx) {
    croak qq(Illegal method: $method);
  }

  if($self->can($method)) {
    if($aspect =~ /_(jpg|png|gif)/mx) {
      return $self->$method();
    }

    $self->$method();

  } else {
    croak qq(Unsupported method: $method);
  }

  my $model   = $self->model();
  my $actions = my $warnings = q[];

  if($aspect !~ /(rss|atom|ajax|xml|json)$/mx) {
    $actions  = $self->actions();
    eval {
      $self->process_template('warnings.tt2', {}, \$warnings);

    } or do {
      #########
      # non-fatal warning - usually warnings.tt2 missing
      #
      carp "Warning: $EVAL_ERROR";
    };
  }

  my $tmpl = $self->template_name();

  for my $copy (qw(logged_in)) {
    $model->{$copy} ||= $self->{$copy};
  }

  my $cfg     = $util->config();
  my $content = q();

  $self->process_template("$tmpl.tt2", {}, \$content);

  return $warnings . $actions . $content || q(No data);
}

sub process_template {
  my ($self, $template, $extra_params, $where_to_ref) = @_;
  my $util   = $self->util();
  my $cfg    = $util->config();
  my ($entity) = (ref $self) =~ /([^:]+)$/mx;
  my $params = {
		requestor   => $util->requestor,
		model       => $self->model(),
		view        => $self,
		entity      => $entity,
		SCRIPT_NAME => $ENV{SCRIPT_NAME},
		HTTP_HOST   => $ENV{HTTP_HOST},
		now         => (strftime '%Y-%m-%dT%H:%M:%S', localtime),
		(map {
		  $_ => $cfg->val('globals',$_)
		} $cfg->Parameters('globals')),
		%{$extra_params||{}},
	       };

  if($where_to_ref) {
    $self->tt->process($template, $params, $where_to_ref) or croak $self->tt->error();

  } else {
    $self->tt->process($template, $params) or croak $self->tt->error();
  }

  return 1;
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

  my $pk = $model->primary_key();

  my @fields = $model->fields();
  if($pk) {
    #########
    # don't leave primary key in field list
    #
    @fields = grep { $_ ne $pk } @fields;
  }

  my $params = {
		map { $_ => $cgi->param($_) } $cgi->param()
	       };

  for my $field (@fields) {
    if(!exists $params->{$field}) {
      next;
    }
    my $v = $params->{$field};

    #########
    # $v here will always be defined
    # but may be false, e.g. $v=q[] or $v=q[0]
    #
    if($self->autoescape()) {
      $v = $cgi->escapeHTML($v);
    }

    $model->$field($v);
  }

  return 1;
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
  return 1;
}

sub read { ## no critic
  return 1;
}

sub delete { ## no critic
  my $self  = shift;
  my $model = $self->model();
  $model->delete() or croak qq(Failed to delete entity: $EVAL_ERROR);
  return 1;
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
  $self->_populate_from_cgi();

  $model->update() or croak qq(Failed to update entity: $EVAL_ERROR);
  return 1;
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
  $self->_populate_from_cgi();

  $model->create() or croak qq(Failed to create entity: $EVAL_ERROR);
  return 1;
}

sub tt {
  my ($self, $tt) = @_;
  my $util = $self->util();

  if($tt) {
    $util->{tt} = $tt;
  }

  if(!$util->{tt}) {
    $util->{tt} = Template->new({
				 PLUGIN_BASE  => 'ClearPress::Template::Plugin',
				 RECURSION    => 1,
				 INCLUDE_PATH => (sprintf q(%s/templates), $util->data_path()),
				 EVAL_PERL    => 1,
				}) or croak $Template::ERROR;
  }
  return $util->{tt};
}

sub decor {
  my $self = shift;
  my $aspect = $self->aspect() || q();

  if($aspect =~ /(rss|atom|ajax|xml|json|js|_png|_jpg)$/mx) {
    return 0;
  }
  return 1;
}

sub output_flush {
  my $self = shift;
  $DEBUG_OUTPUT and carp "output_flush: @{[scalar @{$self->{output_buffer}}]} blobs in queue";
  print @{$self->{output_buffer}} or croak "Error flushing output: $ERRNO";
  $self->output_reset();
  return 1;
}

sub output_buffer {
  my ($self, @args) = @_;
  if(!$self->output_finished()) {
    push @{$self->{output_buffer}}, @args;
    $DEBUG_OUTPUT and carp "output_buffer added (@{[scalar @args]} blobs)";
  }
  return 1;
}

sub output_finished {
  my ($self, $val) = @_;
  if(defined $val) {
    $self->{output_finished} = $val;
    $DEBUG_OUTPUT and carp "output_finished = $val";
  }
  return $self->{output_finished};
}

sub output_end {
  my $self = shift;
  $DEBUG_OUTPUT and carp "output_end: $self";
  $self->output_finished(1);
  return $self->output_flush();
}

sub output_reset {
  my $self = shift;
  $self->{output_buffer} = [];
  $DEBUG_OUTPUT and carp 'output_reset';
  return;
}

sub actions {
  my $self    = shift;
  my $content = q();

  $self->process_template('actions.tt2', {}, \$content);
  return $content;
}

# todo: auto-create these <action>_<format> style accessors

sub list_xml {
  my $self = shift;
  return $self->list();
}

sub read_xml {
  my $self = shift;
  return $self->read();
}

sub create_xml {
  my $self = shift;
  return $self->create();
}

sub update_xml {
  my $self = shift;
  return $self->update();
}

sub delete_xml {
  my $self = shift;
  return $self->delete();
}

sub list_json {
  my $self = shift;
  return $self->list();
}

sub read_json {
  my $self = shift;
  return $self->read();
}

1;
__END__

=head1 NAME

ClearPress::view - MVC view superclass

=head1 VERSION

$LastChangedRevision: 224 $

=head1 SYNOPSIS

  my $oView = ClearPress::view::<subclass>->new({util => $oUtil});
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

  my $oView = ClearPress::view::<subclass>->new({util => $oUtil, ...});

=head2 init - additional post-constructor hook

=head2 determine_aspect - URI processing

 sets the aspect based on the HTTP Accept: header

 - useful for API access setting Accept: text/xml

=head2 template_name - the name of the template to load, based on view class and method_name()

  my $sTemplateName = $oView->template_name();

=head2 method_name - the name of the method to invoke on the model, based on action and aspect

  my $sMethodName = $oView->method_name();

=head2 add_warning

  $oView->add_warning($sWarningMessage);

=head2 warnings - an arrayref of warning strings set for this view

  my $arWarningStrings = $oView->warnings();

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

=head2 entity_name - get/set accessor for the entity_name

 Usually set by the controller, after processing the request. Used for
 remapping requests to classes (specifically things of the form
 application::(model|view)::something::somethingelse .

  $oView->entity_name($sEntityName);
  my $sEntityName = $oView->entity_name();

=head2 actions - templated output for available actions

  my $sActionOutput = $oView->actions();

=head2 list_xml - default passthrough to list() for xml service

=head2 read_xml - default passthrough to read() for xml service

=head2 create_xml - default passthrough to create() for xml service

=head2 update_xml - default passthrough to update() for xml service

=head2 delete_xml - default passthrough to delete() for xml service

=head2 list_json - default passthrough to list() for json service

=head2 read_json - default passthrough to read() for json service

=head2 determine_aspect - calculate requested aspect of view

  Based on HTTP headers, environment variables and URL components.

=head2 init - post-constructor initialisation hook for subclasses

=head2 process_template - process a template with standard parameters

  Process template.tt2 with standard parameters, output to stdout.

  $oView->process_template('template.tt2');


  Process template.tt2 with standard parameters plus extras, output to
  stdout.

  $oView->process_template('template.tt2', {extra=>'params'});


  Process template.tt2 with standard plus extra parameters and output
  into $to_scalar.

  $oView->process_template('template.tt2', {extra=>'params'}, $to_scalar);

=head2 output_buffer - For streamed output: queue a string for output

  $oView->output_buffer(q[my string]);
  $oView->output_buffer(@aStrings);

=head2 output_end - For streamed output: flag no more output and flush buffer

  $oView->output_end();

=head2 output_finished - For streamed output: flag there's no more output

  $oView->output_finished(1);
  $oViwe->output_finished(0);

=head2 output_flush - For streamed output: flush output buffer to STDOUT

  $oView->output_flush();

=head2 output_reset - clear data pending output

  $oView->output_reset();

=head2 autoescape - turn auto-escaping of input on/off, usually in a subclass

 If you're producing applications of moderate complexity, you almost
 certainly want to disable autoescaping and handle it more cleverly
 yourself. Subclass ClearPress::view and set self->autoescape to zero
 or override the subroutine:

 sub autoescape { return 0; }

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item Template

=item ClearPress::util

=item Carp

=item English

=item POSIX

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

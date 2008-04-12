#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-03-28
# Last Modified: $Date: 2007-06-25 09:35:19 +0100 (Mon, 25 Jun 2007) $
# Id:            $Id: controller.pm 12 2007-06-25 08:35:19Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/controller.pm,v $
# $HeadURL$
#
package ClearPress::controller;
use strict;
use warnings;
use English qw(-no_match_vars);
use Carp;
use ClearPress::decorator;
use ClearPress::view::error;
use CGI;

our $VERSION = do { my ($r) = q$LastChangedRevision: 12 $ =~ /(\d+)/mx; $r; };
our $DEBUG   = 0;
our $CRUD    = {
		'POST'   => 'create',
		'GET'    => 'read',
		'PUT'    => 'update',
		'DELETE' => 'destroy',
	       };

sub accept_extensions {
  return [
	  {'.html' => q()},
	  {'.xml'  => '_xml'},
	  {'.png'  => q(_png)},
	  {'.rss'  => q(_rss)},
	  {'.atom' => q(_atom)},
	  {'.js'   => q(_json)},
	  {'.json' => q(_json)},
	  {'.ical' => q(_ical)},
	 ];
}

sub accept_headers {
  return [
#	  {'text/html'        => q()},
	  {'application/json' => q(_json)},
	  {'text/xml'         => q(_xml)},
	 ];
}

sub process_uri {
  my ($self, @args) = @_;
  carp q(process_uri is deprecated. Use process_request());
  return $self->process_request(@args);
}

sub process_request {
  my ($self, $util) = @_;
  my $method        = $ENV{REQUEST_METHOD} || 'GET';
  my $action        = $CRUD->{uc $method};
  my $pi            = $ENV{PATH_INFO}      || q();
  my $accept        = $ENV{HTTP_ACCEPT}    || q();
  my $qs            = $ENV{QUERY_STRING}   || q();
  my ($entity)      = $pi =~ m{^/([^/;\.]+)}mx;
  $entity         ||= q();
  my ($id)          = $pi =~ m{^/$entity/([a-z\-_\d%\@\.\+\ ]+)}mix;
  my ($aspect)      = $pi =~ m{;(\S+)}mx;

  # method id action  aspect  result CRUD
  # =====================================
  # POST   n  create  -       create    *
  # POST   y  create  update  update    *
  # POST   y  create  delete  delete    *
  # GET    n  read    -       list
  # GET    n  read    add     add/new
  # GET    y  read    -       read      *
  # GET    y  read    edit    edit

  if($action eq 'read' && !$id && !$aspect) {
    $aspect = 'list';
  }

  if($action eq 'create' && $id && (!$aspect || $aspect eq 'update')) {
    $action = 'update';
  }

  if($action eq 'create' && $id && $aspect eq 'delete') {
    $action = 'delete';
  }

  $aspect ||= q();

  $DEBUG and carp qq(aspect=@{[$aspect||'undef']});

  my $uriaspect = $self->_process_request_extensions(\$pi, $aspect, $action) || q();
  if($uriaspect ne $aspect) {
    $aspect = $uriaspect;
    ($id)   = $pi =~ m{^/$entity/([a-z\-_\d%\@\.\+\ ]+)}mix;
  }

  $aspect   = $self->_process_request_headers(\$accept, $aspect, $action);
  $entity ||= $util->config->val('application','default_view');
  $aspect ||= q();
  $id       = CGI->unescape($id||'0');

  if(!$entity) {
    my $views = $util->config->val('application', 'views');
    $entity   = (split /[\s,]+/mx, $views)[0];
  }

  return $self->_check_sanity($action, $entity, $aspect, $id);
}

sub _check_sanity {
  my ($self, $action, $entity, $aspect, $id) = @_;

  #########
  # sanity checks
  #
  if($action eq $aspect) {
    $aspect = q();
  }

  if(scalar grep { $_ eq $aspect } values %{$CRUD}) {
    carp qq(Discarding aspect $aspect - should it be an action?);
    $aspect = q();
  }

  $DEBUG and carp qq(_check_sanity: action=$action, entity=$entity, aspect=$aspect, id=$id);
  return ($action, $entity, $aspect, $id);
}

sub _process_request_extensions {
  my ($self, $pi, $aspect, $action) = @_;

  $DEBUG and carp qq(pi=$pi);
  for my $pair (@{$self->accept_extensions}) {
    my ($ext, $meth) = %{$pair};
    $ext =~ s/\./\\./mxg;
    if(${$pi} =~ s/$ext$//mx) {
      $aspect ||= $action;
      $aspect  =~ s/$meth$//mx;
      $aspect .= $meth;
      last;
    }
  }

  $DEBUG and carp qq(aspect=@{[$aspect||'undef']});
  return $aspect;
}

sub _process_request_headers {
  my ($self, $accept, $aspect, $action) = @_;

  $DEBUG and carp qq(accept=$accept);

  for my $pair (@{$self->accept_headers()}) {
    my ($header, $meth) = %{$pair};
    if(${$accept} =~ /$header$/mx) {
      $aspect ||= $action;
      $aspect  =~ s/$meth$//mx;
      $aspect .= $meth;
      last;
    }
  }

  $DEBUG and carp qq(aspect=@{[$aspect||'undef']});
  return $aspect;
}

sub decorator {
  my ($self, $util) = @_;
  my $appname       = $util->config->val('application', 'name') || 'Application';
  my $decorator     = ClearPress::decorator->new({
						  'title'      => (sprintf q(%s v%s),
								   $appname,
								   $VERSION,),
						  'stylesheet' => [$util->config->val('application','stylesheet')],
						 });
  return $decorator;
}

sub handler {
  my ($self, $util) = @_;
  my $decorator     = $self->decorator($util);
  my $namespace     = $util->config->val('application', 'namespace') || $util->config->val('application', 'name');
  my $cgi           = $decorator->cgi();

  my ($action, $entity, $aspect, $id) = $self->process_request($util);

  $util->username($decorator->username());
  $util->session($decorator->session());
  $util->cgi($cgi);

  my $viewobject = $self->dispatch({
				    'util'   => $util,
				    'entity' => $entity,
				    'aspect' => $aspect,
				    'action' => $action,
				    'id'     => $id,
				   });

  my $decor = $viewobject->decor();

  if(!$viewobject->isa('ClearPress::view::error')) {
    $decorator->save_session();
  }

  if($decor) {
    $viewobject->output_buffer($decorator->header());
  }

  eval {
    $viewobject->output_buffer($viewobject->render());
  };
  if($EVAL_ERROR) {
    $viewobject = ClearPress::view::error->new({
						'util'   => $util,
						'action' => 'error',
						'errstr' => $EVAL_ERROR,
					       });
    #########
    # reset headers before printing an error
    #
    $viewobject->output_buffer($decorator->header());
    $decor    = 1;
    $viewobject->output_buffer($viewobject->render());
  }

  #########
  # re-test decor in case it's changed by render()
  #
  if($viewobject->decor()) {
    #########
    # assume it's safe to re-open the output stream (Eesh!)
    #
    $viewobject->output_finished(0);
    $viewobject->output_buffer($decorator->footer());

  } else {
    #########
    # prepend content-type to output buffer
    #
    if(!$viewobject->output_finished()) {
      print qq(X-Generated-By: ClearPress\n);
      print q(Content-type: ), $viewobject->content_type(), "\n\n" or croak q(Failed to print output);
    }
  }

  $viewobject->output_end();

  return;
}

sub dispatch {
  my ($self, $ref) = @_;
  my $util      = $ref->{'util'};
  my $entity    = $ref->{'entity'};
  my $aspect    = $ref->{'aspect'};
  my $action    = $ref->{'action'};
  my $id        = $ref->{'id'};
  my $namespace = $util->config->val('application', 'namespace') || $util->config->val('application', 'name');
  my $viewobject;

  eval {
    my @entities = split /[,\s]+/mx, $util->config->val('application','views');
    if(!scalar grep { $_ eq $entity } @entities) {
      croak qq(No such view ($entity));
    }

    my $modelclass = "${namespace}::model::$entity";
    my $viewclass  = "${namespace}::view::$entity";
    my $modelpk    = $modelclass->primary_key();

    if(!$modelpk) {
      croak qq(Could not load $modelclass);
    }
    my $modelobject = $modelclass->new({
					'util'   => $util,
					$modelpk => $id,
				       });
    if(!$modelobject) {
      croak qq(Failed to load $modelobject);
    }

    $viewobject = $viewclass->new({
				   'util'   => $util,
				   'model'  => $modelobject,
				   'action' => $action,
				   'aspect' => $aspect,
				  });
    if(!$viewobject) {
      croak qq(Failed to load $viewobject);
    }
  };

  if($EVAL_ERROR) {
    $viewobject = ClearPress::view::error->new({
						'util'   => $util,
						'errstr' => $EVAL_ERROR,
					       });
  }

  return $viewobject;
}

1;
__END__

=head1 NAME

ClearPress::controller - Application controller

=head1 VERSION

$LastChangedRevision: 12 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 decorator - get/set accessor for a page decorator implementing the ClearPress::decorator interface

  $oController->decorator($oDecorator);

  my $oDecorator = $oController->decorator();

=head2 accept_extensions - data structure of file-extensions-to-aspect mappings  (e.g. '.xml', '.js') in precedence order

 my $arAcceptedExtensions = $oController->accept_extensions();

 [
  {'.ext' => '_aspect'},
  {'.js'  => '_json'},
 ]

=head2 accept_headers - data structure of accept_header-to-aspect mappings  (e.g. 'text/xml', 'application/javascript') in precedence order

 my $arAcceptedHeaders = $oController->accept_headers();

 [
  {'text/mytype'            => '_aspect'},
  {'application/javascript' => '_json'},
 ]

=head2 process_uri - deprecated. use process_request()

=head2 process_request - extract useful things from %ENV relating to our URI

  my ($sAction, $sEntity, $sAspect, $sId) = $oCtrl->process_request($oUtil);

=head2 handler - run the controller

=head2 dispatch - view generation

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

English
Carp
ClearPress::decorator

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

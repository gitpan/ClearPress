#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-03-28
# Last Modified: $Date: 2008-05-31 00:08:14 +0100 (Sat, 31 May 2008) $
# Id:            $Id: controller.pm 161 2008-05-30 23:08:14Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/controller.pm,v $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/lib/ClearPress/controller.pm $
#
# method id action  aspect  result CRUD
# =====================================
# POST   n  create  -       create    *
# POST   y  create  update  update    *
# POST   y  create  delete  delete    *
# GET    n  read    -       list
# GET    n  read    add     add/new
# GET    y  read    -       read      *
# GET    y  read    edit    edit

package ClearPress::controller;
use strict;
use warnings;
use English qw(-no_match_vars);
use Carp;
use ClearPress::decorator;
use ClearPress::view::error;
use CGI;

our $VERSION = do { my ($r) = q$LastChangedRevision: 161 $ =~ /(\d+)/mx; $r; };
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

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};
  bless $ref, $class;
  return $ref;
}

sub util {
  my ($self, $util) = @_;
  if(defined $util) {
    $self->{util} = $util;
  }
  return $self->{util};
}

sub process_uri {
  my ($self, @args) = @_;
  carp q(process_uri is deprecated. Use process_request());
  return $self->process_request(@args);
}

sub process_request { ## no critic (Subroutines::ProhibitExcessComplexity)
  my ($self, $util) = @_;
  my $method        = $ENV{REQUEST_METHOD} || 'GET';
  my $action        = $CRUD->{uc $method};
  my $pi            = $ENV{PATH_INFO}      || q();
  my $accept        = $ENV{HTTP_ACCEPT}    || q();
  my $qs            = $ENV{QUERY_STRING}   || q();
  my ($entity)      = $pi =~ m{^/([^/;\.]+)}mx;
  $entity         ||= q();
  my ($id)          = $pi =~ m{^/$entity/([a-z:,\-_\d%\@\.\+\ ]+)}mix;
  my ($aspect)      = $pi =~ m{;(\S+)}mx;

  if($action eq 'read' && !$id && !$aspect) {
    $aspect = 'list';
  }

  if($action eq 'create' && $id) {
    if(!$aspect || $aspect eq 'update') {
      $action = 'update';

    } elsif($aspect eq 'delete') {
      $action = 'delete';
    }
  }

  $aspect ||= q();

  my $uriaspect = $self->_process_request_extensions(\$pi, $aspect, $action) || q();
  if($uriaspect ne $aspect) {
    $aspect = $uriaspect;
    ($id)   = $pi =~ m{^/$entity/([a-z:,\-_\d%\@\.\+\ ]+)}mix;
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

sub session {
  my ($self) = @_;
  my $decorator = $self->decorator($self->util());
  return $decorator->session();
}

sub handler {
  my ($self, $util) = @_;
  if(!ref $self) {
    $self = $self->new({util => $util});
  }
  my $decorator     = $self->decorator($util);
  my $namespace     = $util->config->val('application', 'namespace') || $util->config->val('application', 'name');
  my $cgi           = $decorator->cgi();

  my ($action, $entity, $aspect, $id) = $self->process_request($util);

  $util->username($decorator->username());
  $util->session($self->session($util));
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
    $viewobject = $self->build_error_object('ClearPress::view::error', $action, $aspect, $EVAL_ERROR);

    #########
    # reset headers before printing an error
    #
    $decor = $viewobject->decor();
    $viewobject->output_reset();
    if($decor) {
      $viewobject->output_buffer($decorator->header());
    }
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
      print qq(X-Generated-By: ClearPress\n) or croak $OS_ERROR;
      print q(Content-type: ), $viewobject->content_type(), "\n\n" or croak $OS_ERROR;
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
      croak qq(No such view ($entity). Is it in your config.ini?);
    }

    my $entity_name = $entity;
    if($util->config->SectionExists('packagemap')) {
      #########
      # if there are uri-to-package maps, process here
      #
      my $map = $util->config->val('packagemap', $entity);
      if($map) {
	$DEBUG and carp qq[Remapping $entity to $map];
	$entity = $map;
      }
    }

    my $modelclass = "${namespace}::model::$entity";
    my $viewclass  = "${namespace}::view::$entity";
    my $modelpk    = $modelclass->primary_key();

    if(!$modelpk) {
      croak qq(Could not find $entity's primary key. Have you "use"d $modelclass?);
    }
    my $modelobject = $modelclass->new({
					'util'   => $util,
					$modelpk => $id,
				       });
    if(!$modelobject) {
      croak qq(Failed to instantiate $modelobject);
    }
    $viewobject = $viewclass->new({
				   util        => $util,
				   model       => $modelobject,
				   action      => $action,
				   aspect      => $aspect,
				   entity_name => $entity_name,
				  });
    if(!$viewobject) {
      croak qq(Failed to instantiate $viewobject);
    }
  };

  if($EVAL_ERROR) {
    $viewobject = $self->build_error_object('ClearPress::view::error', $action, $aspect, $EVAL_ERROR);
  }

  return $viewobject;
}

sub build_error_object {
  my ($self, $error_pkg, $action, $aspect, $eval_error) = @_;
  return ($error_pkg->new({
			   util   => $self->util(),
			   errstr => $eval_error,
			   aspect => $aspect,
			   action => $action,
			  }));
}

1;
__END__

=head1 NAME

ClearPress::controller - Application controller

=head1 VERSION

$LastChangedRevision: 161 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new

=head2 session

=head2 util

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

=head2 build_error_object - builds an error view object

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item English

=item Carp

=item ClearPress::decorator

=back

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

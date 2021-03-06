# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2007-03-28
# Last Modified: $Date: 2014-02-04 16:06:38 +0000 (Tue, 04 Feb 2014) $
# Id:            $Id: controller.pm 456 2014-02-04 16:06:38Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/controller.pm,v $
# $HeadURL: svn+ssh://zerojinx@svn.code.sf.net/p/clearpress/code/trunk/lib/ClearPress/controller.pm $
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

our $VERSION = do { my ($r) = q$Revision: 456 $ =~ /(\d+)/smx; $r; };
our $CRUD    = {
		POST   => 'create',
		GET    => 'read',
		PUT    => 'update',
		DELETE => 'delete',
                HEAD   => 'null',
                TRACE  => 'null',
	       };
our $REST   = {
	       create => 'POST',
	       read   => 'GET',
	       update => 'PUT|POST',
	       delete => 'DELETE|POST',
	       add    => 'GET',
	       edit   => 'GET',
	       list   => 'GET',
               null   => 'HEAD|TRACE'
	      };
sub accept_extensions {
  return [
	  {'.html' => q[]},
	  {'.xml'  => q[_xml]},
	  {'.png'  => q[_png]},
	  {'.jpg'  => q[_jpg]},
	  {'.rss'  => q[_rss]},
	  {'.atom' => q[_atom]},
	  {'.js'   => q[_json]},
	  {'.json' => q[_json]},
	  {'.ical' => q[_ical]},
	  {'.txt'  => q[_txt]},
	  {'.xls'  => q[_xls]},
	  {'.ajax' => q[_ajax]},
	 ];
}

sub accept_headers {
  return [
#	  {'text/html'        => q[]},
	  {'application/json' => q[_json]},
	  {'text/xml'         => q[_xml]},
	 ];
}

sub new {
  my ($class, $ref) = @_;
  $ref ||= {};
  bless $ref, $class;
  $ref->init();

  eval {
    #########
    # We may be given a database handle from the cache with an open
    # transaction (e.g. from running a few selects), so on controller
    # construction (effectively per-page-view), we rollback any open
    # transaction on the database handle we've been given.
    #
    $ref->util->dbh->rollback();
    1;

  } or do {
    #########
    # ignore any error
    #
    carp q[Failed per-request rollback on fresh database handle];
  };

  return $ref;
}

sub init {
  return 1;
}

sub util {
  my ($self, $util) = @_;
  if(defined $util) {
    $self->{util} = $util;
  }
  return $self->{util};
}

sub packagespace {
  my ($self, $type, $entity, $util) = @_;

  if($type ne 'view' &&
     $type ne 'model') {
    return;
  }

  $util         ||= $self->util();
  my $entity_name = $entity;

  if($util->config->SectionExists('packagemap')) {
    #########
    # if there are uri-to-package maps, process here
    #
    my $map = $util->config->val('packagemap', $entity);
    if($map) {
      $entity = $map;
    }
  }

  my $namespace = $self->namespace($util);
#carp qq[namespace=$namespace, type=$type, entity=$entity caller=],caller();
  return "${namespace}::${type}::$entity";
}

sub process_request { ## no critic (Subroutines::ProhibitExcessComplexity)
  my ($self, $util) = @_;
  my $method        = $ENV{REQUEST_METHOD} || 'GET';
  my $action        = $CRUD->{uc $method};
  my $pi            = $ENV{PATH_INFO}      || q[];
  my $accept        = $ENV{HTTP_ACCEPT}    || q[];
  my $qs            = $ENV{QUERY_STRING}   || q[];
  my $hxrw          = $ENV{HTTP_X_REQUESTED_WITH} || q[];
  my $xhr           = ($hxrw =~ /XMLHttpRequest/smix);

  if($xhr && $pi !~ m{(?:ajax|json|js|xml)(?:/[^/]*?)?$}smx) {
    if($pi =~ /[;]/smx) {
      $pi .= q[_ajax];
    } else {
      $pi .= q[.ajax];
    }
  }

  my ($entity)      = $pi =~ m{^/([^/;.]+)}smx;
  $entity         ||= q[];
  my ($dummy, $aspect_extra, $id) = $pi =~ m{^/$entity(/(.*))?/([[:lower:][:digit:]:,\-_%@.+\s]+)}smix;

  my ($aspect)      = $pi =~ m{;(\S+)}smx;

  if($action eq 'read' && !$id && !$aspect) {
    $aspect = 'list';
  }

  if($action eq 'create' && $id) {
    if(!$aspect || $aspect =~ /^update/smx) {
      $action = 'update';

    } elsif($aspect =~ /^delete/smx) {
      $action = 'delete';
    }
  }

  $aspect ||= q[];
  $aspect_extra ||= q[];

  #########
  # process request extensions
  #
  my $uriaspect = $self->_process_request_extensions(\$pi, $aspect, $action) || q[];
  if($uriaspect ne $aspect) {
    $aspect = $uriaspect;
    ($id)   = $pi =~ m{^/$entity/?$aspect_extra/([[:lower:][:digit:]:,\-_%@.+\s]+)}smix;
  }

  #########
  # process HTTP 'Accept' header
  #
  $aspect   = $self->_process_request_headers(\$accept, $aspect, $action);
  $entity ||= $util->config->val('application', 'default_view');
  $aspect ||= q[];
  $id       = CGI->unescape($id||'0');

  #########
  # no view determined and no configured default_view
  # pull the first one off the list
  #
  if(!$entity) {
    my $views = $util->config->val('application', 'views') || q[];
    $entity   = (split /[\s,]+/smx, $views)[0];
  }

  #########
  # no view determined, no default_view and none in the list
  #
  if(!$entity) {
    croak q[No available views];
  }

  my $viewclass = $self->packagespace('view', $entity, $util);

  if($aspect_extra) {
    $aspect_extra =~ s{/}{_}smxg;
  }

  if($id eq '0') {
    #########
    # no primary key:
    # /thing;method
    # /thing;method_xml
    # /thing.xml;method
    #
    my $tmp = $aspect || $action;
    if($aspect_extra) {
      $tmp =~ s/_/_${aspect_extra}_/smx;

      if($viewclass->can($tmp)) {
	$aspect = $tmp;
      }
    }

  } elsif($id !~ /^\d+$/smx) {
    #########
    # mangled primary key - attempt to match method in view object
    # /thing/method          => list_thing_method (if exists), or read(pk=method)
    # /thing/part1/part2     => list_thing_part1_part2 if exists, or read_thing_part1(pk=part2)
    # /thing/method.xml      => list_thing_method_xml (if exists), or read_thing_xml (pk=method)
    # /thing/part1/part2.xml => list_thing_part1_part2_xml (if exists), or read_thing_part1_xml (pk=part2)
    #

    my $tmp = $aspect;

    if($tmp =~ /_/smx) {
      $tmp =~ s/_/_${id}_/smx;

    } else {
      $tmp = "${action}_$id";

    }

    $tmp =~ s/^read/list/smx;
    $tmp =~ s/^update/create/smx;

    if($aspect_extra) {
      $tmp =~ s/_/_${aspect_extra}_/smx;
    }

    if($viewclass->can($tmp)) {
      $id     = 0;
      $aspect = $tmp;

      #########
      # id has been modified, so reset action
      #
      if($aspect =~ /^create/smx) {
	$action = 'create';
      }

    } else {
      if($aspect_extra) {
	if($aspect =~ /_/smx) {
	  $aspect =~ s/_/_${aspect_extra}_/smx;
	} else {
	  $aspect .= "_$aspect_extra";
	}
      }
    }

  } elsif($aspect_extra) {
    #########
    # /thing/method/50       => read_thing_method(pk=50)
    #
    if($aspect =~ /_/smx) {
      $aspect =~ s/_/_${aspect_extra}_/smx;
    } else {
      $aspect .= "${action}_$aspect_extra";
    }
  }

  #########
  # fix up aspect
  #
  my ($firstpart) = $aspect =~ /^${action}_([^_]+)_?/smx;
  if($firstpart) {
    my $restpart = $REST->{$firstpart};
    if($restpart) {
      ($restpart) = $restpart =~ /^([^|]+)/smx;
      if($restpart) {
	my ($crudpart) = $CRUD->{$restpart};
	if($crudpart) {
	  $aspect =~ s/^${crudpart}_//smx;
	}
      }
    }
  }

  if($aspect !~ /^(?:create|read|update|delete|add|list|edit)/smx) {
    my $action_extended = $action;
    if(!$id) {
      $action_extended = {
			  read => 'list',
			 }->{$action} || $action_extended;
    }
    $aspect = $action_extended . ($aspect?"_$aspect":q[]);
  }

  #########
  # sanity checks
  #
  my ($type) = $aspect =~ /^([^_]+)/smx; # read|list|add|edit|create|update|delete
  if($method !~ /^$REST->{$type}$/smx) {
    croak qq[Bad request. $aspect ($type) is not a $CRUD->{$method} method];
  }

  if(!$id &&
     $aspect =~ /^(?:delete|update|edit|read)/smx) {
    croak qq[Bad request. Cannot $aspect without an id];
  }

  if($id &&
     $aspect =~ /^(?:create|add|list)/smx) {
    croak qq[Bad request. Cannot $aspect with an id];
  }

  $aspect =~ s/__/_/smxg;
  return ($action, $entity, $aspect, $id);
}

sub _process_request_extensions {
  my ($self, $pi, $aspect, $action) = @_;

  my $extensions = join q[], reverse ${$pi} =~ m{([.][^;.]+)}smxg;

  for my $pair (@{$self->accept_extensions}) {
    my ($ext, $meth) = %{$pair};
    $ext =~ s/[.]/\\./smxg;

    if($extensions =~ s{$ext$}{}smx) {
      ${$pi}    =~ s{$ext}{}smx;
      $aspect ||= $action;
      $aspect   =~ s/$meth$//smx;
      $aspect  .= $meth;
    }
  }

  return $aspect;
}

sub _process_request_headers {
  my ($self, $accept, $aspect, $action) = @_;

  for my $pair (@{$self->accept_headers()}) {
    my ($header, $meth) = %{$pair};
    if(${$accept} =~ /$header$/smx) {
      $aspect ||= $action;
      $aspect  =~ s/$meth$//smx;
      $aspect .= $meth;
      last;
    }
  }

  return $aspect;
}

sub decorator {
  my ($self, $util) = @_;

  if(!$self->{decorator}) {
    my $appname   = $util->config->val('application', 'name') || 'Application';
    my $namespace = $self->namespace;
    my $decorpkg  = "${namespace}::decorator";
    my $config    = $util->config;
    my $decor;

    eval {
      require $decorpkg;
      $decor = $decorpkg->new();
    } or do {
      $decor = ClearPress::decorator->new();
    };

    for my $field ($decor->fields) {
      $decor->$field($config->val('application', $field));
    }

    if(!$decor->title) {
      $decor->title($config->val('application', 'name') || 'ClearPress Application');
    }

    $self->{decorator} = $decor;
  }

  return $self->{decorator};
}

sub session {
  my ($self, $util) = @_;
  my $decorator = $self->decorator($util || $self->util());
  return $decorator->session() || {};
}

sub handler {
  my ($self, $util) = @_;
  if(!ref $self) {
    $self = $self->new({util => $util});
  }

  my $cgi           = $util->cgi();
  my $decorator     = $self->decorator($util);
  my $namespace     = $self->namespace($util);

  my ($action, $entity, $aspect, $id) = $self->process_request($util);

  $util->username($decorator->username());
  $util->session($self->session($util));

  my $viewobject = $self->dispatch({
				    util   => $util,
				    entity => $entity,
				    aspect => $aspect,
				    action => $action,
				    id     => $id,
				   });

  my $decor = $viewobject->decor();

  #########
  # let the view have the decorator in case it wants to modify headers
  #
  $viewobject->decorator($decorator);

  if($decor) {
    if($viewobject->charset && $decorator->can('charset')) {
      $decorator->charset($viewobject->charset);
    }

    my $content_type = $viewobject->content_type();
    my $charset      = $viewobject->charset();
    if($content_type =~ /text/smx && $charset =~ /utf-?8/smix) {
      binmode STDOUT, q[:encoding(UTF-8)];
    }

    $viewobject->output_buffer($decorator->header());
  }

  eval {
    $viewobject->output_buffer($viewobject->render());

  } or do {
    $viewobject = $self->build_error_object("${namespace}::view::error",
					    $action,
					    $aspect,
					    $EVAL_ERROR);

    #########
    # reset headers before printing an error
    #
    $decor = $viewobject->decor();
    $viewobject->output_reset();
    if($decor) {
      $viewobject->output_buffer($decorator->header());
    }
    $viewobject->output_buffer($viewobject->render());
  };

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
      print qq(X-Generated-By: ClearPress\n) or croak $ERRNO;

      my $charset = $viewobject->charset();
      if(defined $charset) {
	$charset = qq[; charset="$charset"];
      }

      my $content_type = $viewobject->content_type();
      $content_type = qq[Content-type: $content_type$charset\n\n];

      print $content_type or croak $ERRNO;
    }
  }

  $viewobject->output_end();

  #########
  # save the session after the request has processed
  #
  if(!$viewobject->isa('ClearPress::view::error')) {
    $decorator->save_session();
  }

  $util->cleanup();
  undef $util;
  return 1;
}

sub namespace {
  my ($self, $util) = @_;
  my $ns   = q[];

  if((ref $self && !$self->{namespace}) || !ref $self) {
    $util ||= $self->util();
    $ns = $util->config->val('application', 'namespace') ||
          $util->config->val('application', 'name') ||
	  'ClearPress';
    if(ref $self) {
      $self->{namespace} = $ns;
    }
  } else {
    $ns = $self->{namespace};
  }

  return $ns;
}

sub is_valid_view {
  my ($self, $ref, $viewname) = @_;
  my $util     = $ref->{util};
  my @entities = split /[,\s]+/smx, $util->config->val('application','views');

  if(!scalar grep { $_ eq $viewname } @entities) {
    return;
  }

  return 1;
}

sub dispatch {
  my ($self, $ref) = @_;
  my $util      = $ref->{util};
  my $entity    = $ref->{entity};
  my $aspect    = $ref->{aspect};
  my $action    = $ref->{action};
  my $id        = $ref->{id};
  my $viewobject;

  eval {
    my $state = $self->is_valid_view($ref, $entity);
    if(!$state) {
      croak qq(No such view ($entity). Is it in your config.ini?);
    }

    my $entity_name = $entity;
    my $modelclass  = $self->packagespace('model', $entity, $util);
    my $viewclass   = $self->packagespace('view',  $entity, $util);

    my $modelpk     = $modelclass->primary_key();
    my $modelobject = $modelclass->new({
					util => $util,
					$modelpk?($modelpk => $id):(),
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
    1;

  } or do {
    my $namespace = $self->namespace($util);
    $viewobject   = $self->build_error_object("${namespace}::view::error", $action, $aspect, $EVAL_ERROR);
  };

  return $viewobject;
}

sub build_error_object {
  my ($self, $error_pkg, $action, $aspect, $eval_error) = @_;
  my $obj;
  my $ref = {
	     util   => $self->util(),
	     errstr => $eval_error,
	     aspect => $aspect,
	     action => $action,
	    };
  eval {
    $obj = $error_pkg->new($ref);
  } or do {
    $obj = ClearPress::view::error->new($ref);
  };

  return $obj;
}

1;
__END__

=head1 NAME

ClearPress::controller - Application controller

=head1 VERSION

$Revision: 456 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - constructor, usually no specific arguments

 my $oController = application::controller->new();

=head2 init - post-constructor initialisation, called after new()

 $oController->init();

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

=head2 namespace - top-level package namespace from config.ini

  my $sNS = $oCtrl->namespace();
  my $sNS = app::controller->namespace();

=head2 packagespace - mangled namespace given a package- and entity-type

  my $pNS = $oCtrl->packagespace('model', 'entity_type');
  my $pNS = $oCtrl->packagespace('view',  'entity_type');
  my $pNS = app::controller->packagespace('model', 'entity_type', $oUtil);
  my $pNS = app::controller->packagespace('view',  'entity_type', $oUtil);

=head2 dispatch - view generation

=head2 is_valid_view - view-name validation

=head2 build_error_object - builds an error view object

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item English

=item Carp

=item ClearPress::decorator

=item ClearPress::view::error

=item CGI

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

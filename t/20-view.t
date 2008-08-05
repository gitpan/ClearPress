use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use t::util;
use IO::Scalar;
use t::model;
use CGI;
use t::user::admin;
use t::user::basic;
use Test::Trap;
use Carp;

eval {
  require DBD::SQLite;
  plan tests => 62;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use_ok('ClearPress::view');

$ClearPress::view::DEBUG_OUTPUT = 0;

my $util = t::util->new();

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  isa_ok($view, 'ClearPress::view', 'constructs ok with ref');
}

{
  my $view = ClearPress::view->new();
  isa_ok($view, 'ClearPress::view', 'constructs ok without ref');
}

{
  $util->username('joe_user');
  is($util->username(), 'joe_user', 'username set');
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  isa_ok($view, 'ClearPress::view', 'constructs ok with ref');
  $util->username(undef);
  is($util->username(), undef, 'username unset');
}

{
  my $types = {
	       _xml  => 'text/xml',
	       _rss  => 'text/xml',
	       _atom => 'text/xml',
	       _ajax => 'text/xml',
	       _js   => 'application/javascript',
	       _json => 'application/javascript',
	       _png  => 'image/png',
	       _jpg  => 'image/jpeg',
	       q[]   => 'text/html',
	      };
  for my $k (keys %{$types}) {
    my $view = ClearPress::view->new({
				      util   => $util,
				      aspect => "read$k",
				     });
    is($view->content_type(), $types->{$k}, "$k => $types->{$k} content_type");
  }
}

{
  my $view = ClearPress::view->new({
				    util   => $util,
				   });
  is($view->decor(), 1, 'decorate when no aspect given');

  my $types = {
	       _xml  => 0,
	       _rss  => 0,
	       _atom => 0,
	       _ajax => 0,
	       _js   => 0,
	       _json => 0,
	       _png  => 0,
	       _jpg  => 0,
	       q[]   => 1,
	      };
  for my $k (keys %{$types}) {
    my $view = ClearPress::view->new({
				      util   => $util,
				      aspect => "read$k",
				     });
    is($view->decor(), $types->{$k}, "$k => $types->{$k} decor");
  }
}

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  is((scalar @{$view->warnings}), 0, 'no warnings present');
  $view->add_warning('a warning');
  is((scalar @{$view->warnings}), 1, '1 warning present');
  is($view->warnings->[0], 'a warning', 'correct warning present');
}

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  trap {
    is($view->_accessor('key', 'value'), 'value', 'accessor set value');
    is($view->_accessor('key'), 'value', 'accessor get value');
  };

  like($trap->stderr(), qr/deprecated/smx, 'deprecated warn');
}

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });

  my $io     = IO::Scalar->new();
  my $stdout = select $io;

  $view->output_buffer("Content-type: text/html\n\n");
  $view->output_reset();
  $view->output_buffer("Content-type: text/plain\n\n");
  $view->output_end();
  $view->output_buffer("Content-type: text/plain\n\n");

  select $stdout;

  is($io, "Content-type: text/plain\n\n", 'output buffer ok without debugging');
}

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });

  $ClearPress::view::DEBUG_OUTPUT = 1;

  my $io     = IO::Scalar->new();
  my $stdout = select $io;

  trap {
    $view->output_buffer("Content-type: text/html\n\n");
    $view->output_reset();
    $view->output_buffer("Content-type: text/plain\n\n");
    $view->output_end();
    $view->output_buffer("Content-type: text/plain\n\n");
  };
  like($trap->stderr, qr/output_/mx, 'output buffer debugging');
  select $stdout;

  is($io, "Content-type: text/plain\n\n", 'output buffer ok with debugging');
}

{
  my $model = t::model->new({util=>$util});
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'list',
				     aspect => q(),
				    });

  is($view->template_name(), 'view_list', 'view_list template_name');
}

{
  my $model = t::model->new({util=>$util});
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q(),
				    });

  is($view->template_name(), 'view_list', 'fix read / view_list template_name');
}

{
  my $cgi   = CGI->new();
  $cgi->param('test_field', 'blabla');
  $cgi->param('test_pk',    'two');

  $util->cgi($cgi);

  my $model = t::model->new({
			     util    => $util,
			     test_pk => 'one',
			    });
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q[],
				    });

  is($view->add(), 1, 'add ok');

  is($model->test_field(), 'blabla', 'test field');
  is($model->test_pk(), 'one', 'test pk remains unmodified');

  for my $method (qw(create read update delete)) {
    is($view->$method(), 1, "$method ok");
    my $method_xml = "${method}_xml";
    is($view->$method_xml(), 1, "$method_xml ok");
  }

  $util->cgi(undef);
}

{
  my $model = t::model->new({util=>$util});
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q(),
				    });
  is($view->authorised(), 1, 'always authorised when authentication unsupported');
}

{
  my $model = t::model->new({util=>$util});
  my $basic = t::user::basic->new({util=>$util});
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q(),
				    });
  is($view->authorised(), undef, 'basic user cannot create');
}

{
  my $model = t::model->new({util=>$util});
  my $basic = t::user::basic->new({util=>$util});
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q(),
				    });
  is($view->authorised(), 1, 'basic user can read');
}

{
  my $model = t::model->new({util=>$util});
  my $basic = t::user::basic->new({util=>$util});
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'list',
				     aspect => q(),
				    });
  is($view->authorised(), 1, 'basic user can list');
}

{
  my $model = t::model->new({util=>$util});
  my $basic = t::user::basic->new({util=>$util});
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q(add),
				    });
  is($view->authorised(), undef, 'basic user cannot add');
}

{
  my $model = t::model->new({util=>$util});
  my $basic = t::user::basic->new({util=>$util});
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q(update),
				    });
  is($view->authorised(), undef, 'basic user cannot update');
}

{
  my $model = t::model->new({util=>$util});
  my $basic = t::user::basic->new({util=>$util});
  is($util->requestor($basic), $basic, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'edit',
				     aspect => q(delete),
				    });
  is($view->authorised(), undef, 'basic user cannot delete');
}

{
  my $model = t::model->new({util=>$util});
  my $admin = t::user::admin->new({util=>$util});
  is($util->requestor($admin), $admin, 'requestor set');
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q(),
				    });
  is($view->authorised(), 1, 'admin user can create');
}

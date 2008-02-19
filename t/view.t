use strict;
use warnings;
use Test::More tests => 24;
use English qw(-no_match_vars);
use t::util;
use t::dbh;
use IO::Scalar;
use t::model;
use CGI;
use t::user::admin;
use t::user::basic;

use_ok('ClearPress::view');

$ClearPress::view::DEBUG_OUTPUT = 0;

my $mock = {};
my $dbh  = t::dbh->new({mock=>$mock});
my $util = t::util->new({dbh=>$dbh});

{
  my $view = ClearPress::view->new({
				    util => $util,
				   });
  isa_ok($view, 'ClearPress::view', 'constructs ok');
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

  $view->output_buffer("Content-type: text/html\n\n");
  $view->output_reset();
  $view->output_buffer("Content-type: text/plain\n\n");
  $view->output_end();
  $view->output_buffer("Content-type: text/plain\n\n");

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

  is($view->template_name(), 'view_list');
}

{
  my $model = t::model->new({util=>$util});
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q(),
				    });

  is($view->template_name(), 'view_list');
}

{
  my $cgi   = CGI->new();
  $cgi->param('test_field', 'blabla');
  my $util  = t::util->new({cgi=>$cgi});
  my $model = t::model->new({util=>$util});
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'read',
				     aspect => q(),
				    });

  is($view->add(), undef, 'add ok');

  is($model->test_field(), 'blabla');

  for my $method (qw(create read update delete)) {
    is($view->$method(), undef, "$method ok");
    my $method_xml = "${method}_xml";
    is($view->$method_xml(), undef, "$method_xml ok");
  }
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
  my $util  = t::util->new({requestor=>$basic});
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
  my $util  = t::util->new({requestor=>$basic});
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
  my $util  = t::util->new({requestor=>$basic});
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
  my $util  = t::util->new({requestor=>$basic});
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
  my $util  = t::util->new({requestor=>$basic});
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
  my $util  = t::util->new({requestor=>$basic});
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
  my $util  = t::util->new({requestor=>$admin});
  my $view  = ClearPress::view->new({
				     util   => $util,
				     model  => $model,
				     action => 'create',
				     aspect => q(),
				    });
  is($view->authorised(), 1, 'admin user can create');
}

use strict;
use warnings;
use Test::More;
use t::util;
use English qw(-no_match_vars);
use Test::Trap;

eval {
  require DBD::SQLite;
  plan tests => 51;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

our $CTRL = 'ClearPress::controller';
use_ok($CTRL);

my $util = t::util->new();

my $T = [
	 ['GET', '/thing/method',              '', {}, 'read',  'thing', 'read', 'method'],
	 ['GET', '/thing2/method',             '', {}, 'read',  'thing2', 'list_method', 0],
	 ['GET', '/thing/method/50',           '', {}, 'read',  'thing', 'read_method', 50],
	 ['GET', '/thing3/avg/by/pos',         'id_run=1234', {}, 'read', 'thing3', 'list_avg_by_pos', 0],
	 ['GET', '/thing4/avg/by/pos.xml',     'id_run=1234', {}, 'read', 'thing4', 'list_avg_by_pos_xml', 0],
	 ['GET', '/thing5/avg/by/pos.xml',     'id_run=1234', {}, 'read', 'thing5', 'read_avg_by_xml', 'pos'],
	 ['GET', '/thing',                     '', {}, 'read',   'thing', 'list',     0],
	 ['GET', '/thing/1',                   '', {}, 'read',   'thing', 'read',     1],
	 ['GET', '/thing.xml',                 '', {}, 'read',   'thing', 'list_xml', 0],
	 ['GET', '/thing/1.xml',               '', {}, 'read',   'thing', 'read_xml', 1],
	 ['GET', '/thing;list_xml',            '', {}, 'read',   'thing', 'list_xml', 0],
	 ['GET', '/thing;do_stuff',            '', {}, 'read',   'thing', 'list_do_stuff', 0],
	 ['GET', '/thing/1;read_xml',          '', {}, 'read',   'thing', 'read_xml', 1],
	 ['GET', '/thing;add',                 '', {}, 'read',   'thing', 'add',      0],
	 ['GET', '/thing;add_xml',             '', {}, 'read',   'thing', 'add_xml',  0],
	 ['GET', '/thing.xml;add',             '', {}, 'read',   'thing', 'add_xml',  0],
	 ['GET', '/thing/released/cluster.xml', '', {}, 'read', 'thing', 'read_released_xml', 'cluster'],

	 ['GET', '/user/me@example.com;edit',  '', {}, 'read',   'user',   'edit', 'me@example.com'],
	 ['GET', '/thing/heatmap.png',         '', {}, 'read',   'thing',  'read_png', 'heatmap'],
	 ['GET', '/thing5/heatmap.png',        '', {}, 'read',   'thing5', 'list_heatmap_png',   0],
	 ['GET', '/thing9/heatmap',            '', {}, 'read',   'thing9', 'list_heatmap',       0],
	 ['GET', '/thing/heatmap/45.png',      '', {}, 'read',   'thing',  'read_heatmap_png',   45],
	 ['POST', '/thing/heatmap/45.png',     '', {}, 'update', 'thing',  'update_heatmap_png', 45],

	 ['POST', '/thing',                    '', {}, 'create', 'thing', 'create', 0],
	 ['POST', '/thing.xml',                '', {}, 'create', 'thing', 'create_xml', 0],
	 ['POST', '/thing;create_xml',         '', {}, 'create', 'thing', 'create_xml', 0],
	 ['POST', '/thing/10',                 '', {}, 'update', 'thing', 'update', 10],
	 ['POST', '/thing/10.xml',             '', {}, 'update', 'thing', 'update_xml', 10],
	 ['POST', '/thing/10;update_xml',      '', {}, 'update', 'thing', 'update_xml', 10],
	 ['POST', '/thing10/heatmap.png',      '', {}, 'create', 'thing10', 'create_heatmap_png', 0],

	 ['POST', '/thing6/batch.xml',         '', {}, 'create', 'thing6', 'create_batch_xml', 0],
	 ['POST', '/thing6/batch.xml',         '', {
						    HTTP_ACCEPT => 'text/xml',
						   }, 'create', 'thing6', 'create_batch_xml', 0],
#	 ['POST', '/thing7/batch',             '', {
#						    HTTP_X_REQUESTED_WITH => 'XMLHttpRequest',
#						   },  'create', 'thing7', 'create_batch_ajax', 0], ###### fail
	 ['POST', '/thing7;create_batch',      '', {
						    HTTP_X_REQUESTED_WITH => 'XMLHttpRequest',
						   },  'create', 'thing7', 'create_batch_ajax', 0],
	 ['POST', '/thing7;create_batch_ajax', '', {}, 'create', 'thing7', 'create_batch_ajax', 0],
	 ['POST', '/thing8/batch.xml',         '', {
						    HTTP_X_REQUESTED_WITH => 'XMLHttpRequest',
						   },  'create', 'thing8', 'create_batch_xml', 0],
	 ['DELETE', '/thing/10',               '', {}, 'delete', 'thing', 'delete', 10],
	 ['POST',   '/thing/10;delete',        '', {}, 'delete', 'thing', 'delete', 10],

	 ['GET', '/testmap/test.xml',          '', {}, 'read', 'testmap', 'list_test_xml', 0],
	];

{
  no warnings;
  *{t::view::thing2::list_method}         = sub { return 1; };
  *{t::view::thing3::list_avg_by_pos}     = sub { return 1; };
  *{t::view::thing4::list_avg_by_pos_xml} = sub { return 1; };
  *{t::view::thing5::list_heatmap_png}    = sub { return 1; };
  *{t::view::thing6::create_batch_xml}    = sub { return 1; };
  *{t::view::thing7::create_batch_ajax}   = sub { return 1; };
  *{t::view::thing8::create_batch_xml}    = sub { return 1; };
  *{t::view::thing9::list_heatmap}        = sub { return 1; };
  *{t::view::thing10::create_heatmap_png} = sub { return 1; };
  *{t::view::foo::test::list_test_xml}    = sub { return 1; }; # packagemapped
}

{
  is($CTRL->packagespace('view', 'testmap', $util),
     't::view::foo::test',
     'packagemapped space');
}

for my $t (@{$T}) {
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => $t->[0],
		PATH_INFO      => $t->[1],
		QUERY_STRING   => $t->[2],
		%{$t->[3]},
	       );
  my $ref = [];
  eval {
    $ref = [$CTRL->process_request($util)];

  } or do {
    diag($EVAL_ERROR);
  };

  is((join q[,], @{$ref}),
     (join q[,], @{$t}[4..7]),
     "$t->[0] $t->[1]?$t->[2] => $t->[4],$t->[5],$t->[6],$t->[7]");
}

my $B = [
	 ['POST', '/thing/10;read_xml', '', {}, 'update vs. read'],
	 ['POST', '/thing;read',        '', {}, 'create vs. read'],
	 ['GET',  '/thing/10;delete',   '', {}, 'read vs. delete'],
	 ['GET',  '/thing;read',        '', {}, 'read without id'],
	 ['POST', '/thing;update',      '', {}, 'update without id'],
	 ['GET',  '/thing;edit',        '', {}, 'edit without id'],
	 ['POST', '/thing;delete',      '', {}, 'delete without id'],
	 ['POST', '/thing/10;create',   '', {}, 'create with id'],
	 ['GET',  '/thing/10;list',     '', {}, 'list with id'],
	 ['GET',  '/thing/10;add',      '', {}, 'add with id'],
	 ];

for my $b (@{$B}) {
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => $b->[0],
		PATH_INFO      => $b->[1],
		QUERY_STRING   => $b->[2],
		%{$b->[3]},
	       );
  my $ref = [];
  eval {
    $ref = [$CTRL->process_request($util)];
  };
  if(scalar @{$ref}) {
    diag(join q[,], @{$ref});
  }
  like($EVAL_ERROR, qr/Bad[ ]request/smx, $b->[4]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10',
	       );
  trap {
    $CTRL->handler($util);
  };

  like($trap->stdout, qr/charset=UTF-8/smx, 'header is UTF-8 by default');
}

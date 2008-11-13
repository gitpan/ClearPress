use strict;
use warnings;
use Test::More;
use t::util;
use English qw(-no_match_vars);

eval {
  require DBD::SQLite;
  plan tests => 44;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

our $CTRL = 'ClearPress::controller';
use_ok($CTRL);

my $util = t::util->new();

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/method',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'read', 'method'],
	    'get /thing/method => read (pk=method)');
}

{
  {
    package t::view::thing2;
    use strict;
    use warnings;

    sub list_method {
    }
    1;
  }
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing2/method',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing2', 'list_method', 0],
	    'get /thing2/method => list_method (exists)');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/method/50',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'read_method', 50],
	    'get /thing/method/50 => read_method (pk=50)');
}

{
  {
    package t::view::errors_by_cycle;
    use strict;
    use warnings;

    sub list_ave_by_position {
    }
    1;
  }

  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[id_run=1234],
		PATH_INFO      => '/errors_by_cycle/ave/by/position',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'errors_by_cycle', 'list_ave_by_position', 0],
	    'get /errors_by_cycle/ave/by/position => list_ave_by_position');
}


{
  {
    package t::view::errors_by_cycle;
    use strict;
    use warnings;

    sub list_ave_by_position_xml {
    }
    1;
  }

  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[id_run=1234],
		PATH_INFO      => '/errors_by_cycle/ave/by/position.xml',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'errors_by_cycle', 'list_ave_by_position_xml', 0],
	    'get /errors_by_cycle/ave/by/position.xml => list_ave_by_position_xml');
}

{
  {
    package t::view::errors_by_cycle2;
    use strict;
    use warnings;

    1;
  }

  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[id_run=1234],
		PATH_INFO      => '/errors_by_cycle2/ave/by/position.xml',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'errors_by_cycle2', 'read_ave_by_xml', 'position'],
	    'get /errors_by_cycle2/ave/by/position.xml => read_ave_by_xml');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'list', 0],
	    'get /thing => list');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/1',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'read', 1],
	    'get /thing/1 => read');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/1.xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'read_xml', 1],
	    'get /thing/1.xml => read_xml');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing.xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'list_xml', 0],
	    'get /thing.xml => list_xml');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing;list_xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'list_xml', 0],
	    'get /thing;list_xml => list_xml (old-style)');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10;read_xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'read_xml', 10],
	    'get /thing/10;read_xml => read_xml (old-style)');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['create', 'thing', 'create', 0],
	    'post /thing => create');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing.xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['create', 'thing', 'create_xml', 0],
	    'post /thing.xml => create_xml');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing;create_xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['create', 'thing', 'create_xml', 0],
	    'post /thing;create_xml => create_xml (old-style)');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['update', 'thing', 'update', 10],
	    'post /thing/10 => update');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10;update',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['update', 'thing', 'update', 10],
	    'post /thing/10;update => update (old-style)');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10;delete',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['delete', 'thing', 'delete', 10],
	    'post /thing/10;delete => delete');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/;add',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'add', 0],
	    'get /thing;add => add');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/;add_xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'add_xml', 0],
	    'get /thing/;add_xml => add_xml (old-style)');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing.xml;add',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'add_xml', 0],
	    'get /thing.xml;add => add_xml');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/user/me@example.com;edit',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'user', 'edit', 'me@example.com'],
	    'get /user/me@example.com;edit => edit (extended characters)');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/heatmap.png',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'read_png', 'heatmap'],
	   'get /thing/heatmap.png => read_png (generic view)');
}

{
  {
    package t::view::thing2;
    use strict;
    use warnings;

    sub list_heatmap_png {
    }
    1;
  }

  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing2/heatmap.png',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing2', 'list_heatmap_png', 0],
	    'get /thing2/heatmap.png => list_heatmap_png (specialised view)');
}


{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/heatmap/45.png',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'read_heatmap_png', 45],
	    'get /thing/heatmap/45.png => read_heatmap_png');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/heatmap/45.png',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['update', 'thing', 'update_heatmap_png', 45],
	    'post /thing/heatmap/45.png => update_heatmap_png');
}

{
  {
    package t::view::thing;
    use strict;
    use warnings;

    sub list_heatmap {
    }
    1;
  }

  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/heatmap',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'list_heatmap', 0],
	    'get /thing/heatmap => list_heatmap (customised)');
}

{
  {
    package t::view::thing2;
    use strict;
    use warnings;

    sub create_heatmap_png {
    }
    1;
  }
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing2/heatmap.png',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['create', 'thing2', 'create_heatmap_png', 0],
	    'post /thing2/heatmap.png => create_heatmap_png');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/released/cluster.xml',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing', 'read_released_xml', 'cluster'],
	    'get /thing/released/cluster.xml => read_released_cluster (multi-depth call)');
}

{
  is($CTRL->packagespace('view', 'testmap', $util),
     't::view::foo::test',
     'packagemapped space');
}

{
  {
    package t::view::foo::test;
    use strict;
    use warnings;

    sub list_test_xml {
    }
    1;
  }
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/testmap/test.xml',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'testmap', 'list_test_xml', 0],
	    'extended aspect processing including packagemap');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/entry/40;confirm_delete',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'entry', 'read_confirm_delete', 40],
	    'get /entry/40;confirm_delete => read_confirm_delete');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/entry;do_stuff',
	       );

  is_deeply([$CTRL->process_request($util)],
	    ['read', 'entry', 'list_do_stuff', 0],
	    'get /entry;do_stuff => list_do_stuff');
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10;read_xml',
	       );
  eval {
    $CTRL->process_request($util);
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent update vs. read]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing;read',
	       );
  eval {
    $CTRL->process_request($util);
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent create vs. read]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10;delete',
	       );
  eval {
    $CTRL->process_request($util);
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent read vs. delete]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing;read',
	       );
  eval {
    use Data::Dumper; diag(Dumper($CTRL->process_request($util)));
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent read without id]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing;update',
	       );
  eval {
    use Data::Dumper; diag(Dumper($CTRL->process_request($util)));
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent update without id]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing;edit',
	       );
  eval {
    use Data::Dumper; diag(Dumper($CTRL->process_request($util)));
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent edit without id]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing;delete',
	       );
  eval {
    use Data::Dumper; diag(Dumper($CTRL->process_request($util)));
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent delete without id]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10;create',
	       );
  eval {
    use Data::Dumper; diag(Dumper($CTRL->process_request($util)));
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent create with id]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10;list',
	       );
  eval {
    use Data::Dumper; diag(Dumper($CTRL->process_request($util)));
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent list with id]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => 't/htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q[],
		PATH_INFO      => '/thing/10;add',
	       );
  eval {
    use Data::Dumper; diag(Dumper($CTRL->process_request($util)));
  };
  like($EVAL_ERROR, qr/Bad\ request/mx, q[trap inconsistent add with id]);
}


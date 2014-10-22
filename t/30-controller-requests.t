use strict;
use warnings;
use Test::More;

eval {
  require DBD::SQLite;
  plan tests => 6;
} or do {
  plan skip_all => 'DBD::SQLite not installed';
};

use t::model::derived;
use t::view::derived;
use t::view::error;
use t::request;
use t::util qw(is_rendered_xml is_rendered_js);

my $util = t::util->new();

{
  my $str = t::request->new({
			     PATH_INFO      => '/derived',
			     REQUEST_METHOD => 'GET',
			     util           => $util,
			    });
  is_rendered_xml($str, 'derived_list.html', 'derived list');
}

{
  my $str = t::request->new({
			     PATH_INFO      => '/derived.xml',
			     REQUEST_METHOD => 'GET',
			     util           => $util,
			    });
  is_rendered_xml($str, 'derived_list.xml', 'derived list xml');
}

{
  my $str = t::request->new({
			     PATH_INFO      => '/derived.ajax',
			     REQUEST_METHOD => 'GET',
			     util           => $util,
			    });
  is_rendered_xml($str, 'derived_list.ajax', 'derived list ajax');
}

{
  my $str = t::request->new({
			     PATH_INFO      => '/derived.js',
			     REQUEST_METHOD => 'GET',
			     util           => $util,
			    });
  is_rendered_js($str, 'derived_list.js', 'derived list js');
}

{
  my $str = t::request->new({
			     PATH_INFO      => '/derived',
			     REQUEST_METHOD => 'POST',
			     util           => $util,
			     cgi_params     => {
					       },
			    });
  is_rendered_xml($str, 'derived_create.html', 'derived create');
}

{
  my $str = t::request->new({
			     PATH_INFO      => '/derived/1;update_xml',
			     REQUEST_METHOD => 'POST',
			     util           => $util,
			     cgi_params     => {
					       },
			    });
  is_rendered_xml($str, 'derived_update.html', 'derived update');
}

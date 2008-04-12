use strict;
use warnings;
use Test::More tests => 16;
use ClearPress::util;

our $CTRL = 'ClearPress::controller';
use_ok($CTRL);

my $util = ClearPress::util->new();

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing','list',0]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing/1',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing','',1]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing/1.xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing','read_xml',1]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing.xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing','list_xml',0]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing;list_xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing','list_xml',0]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing/10;read_xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing','read_xml',10]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['create', 'thing','',0]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing.xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['create', 'thing','create_xml',0]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing;create_xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['create', 'thing','create_xml',0]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing/10',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['update', 'thing','',10]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing/10;update',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['update', 'thing','',10]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'POST',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing/10;delete',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['delete', 'thing','',10]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing/;add',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing','add',0]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/thing/;add_xml',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'thing','add_xml',0]);
}

{
  local %ENV = (
		DOCUMENT_ROOT  => './htdocs',
		REQUEST_METHOD => 'GET',
		QUERY_STRING   => q(),
		PATH_INFO      => '/user/me@example.com;edit',
	       );
  is_deeply([$CTRL->process_request($util)],
	    ['read', 'user','edit','me@example.com']);
}

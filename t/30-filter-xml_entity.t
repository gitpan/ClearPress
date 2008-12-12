use strict;
use warnings;
use Test::More tests => 4;
use Template::Context;
use XML::LibXML;

our $FILTER = 'ClearPress::Template::Plugin::xml_entity';
use_ok($FILTER);

my $f = $FILTER->new(Template::Context->new());
isa_ok($f, $FILTER);

my $str = q[êÀÈ];


is($f->filter($str), q[&#xEA;&#xC0;&#xC8;], 'filter');

my $xml = qq[<foo>@{[$f->filter($str)]}</foo>];
ok(XML::LibXML->new->parse_string($xml), 'LibXML happy with numeric entities');

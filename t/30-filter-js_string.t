use strict;
use warnings;
use Test::More tests => 3;
use Template::Context;

our $FILTER = 'ClearPress::Template::Plugin::js_string';
use_ok($FILTER);

my $f = $FILTER->new(Template::Context->new());
isa_ok($f, $FILTER);

is($f->filter(qq[\n"\r]), '\n\"\r', 'filter');

use strict;
use warnings;
use Test::More tests => 18;
use English qw(-no_match_vars);

use_ok('ClearPress::decorator');

{
  my $dec = ClearPress::decorator->new();
  isa_ok($dec, 'ClearPress::decorator', 'constructs without an argument');
}

{
  my $dec = ClearPress::decorator->new({});
  isa_ok($dec, 'ClearPress::decorator', 'constructs with an argument');
  is($dec->title('foo'), 'foo', 'able to set+get the title');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->defaults('meta_content_type'), 'text/html', 'has default content_type of text/html');
  is($dec->meta_content_type(), 'text/html', 'supports meta_content_type() method');
  is($dec->get('junk'), undef, 'returns undef on non-existent attribute fetch');
  is(scalar $dec->get('jsfile'), 0, 'returns empty array on jsfile fetch');
  my $ref = ['/foo.js'];
  if($ClearPress::decorator::DEFAULTS) {
    $ClearPress::decorator::DEFAULTS->{'jsfile'} = $ref;
  }
  is(scalar $dec->jsfile(), 1, 'returns default array for jsfile()');

  $dec->jsfile($ref);
  is(scalar $dec->jsfile(), 1, 'returns given array for jsfile()');
}

{
  $ClearPress::decorator::DEFAULTS->{meta_version} = 123;
  my $dec = ClearPress::decorator->new();
  is($dec->header(), from_file(q(header-1.frag)), 'default combined header');
}

{
  my $dec = ClearPress::decorator->new();
  isa_ok($dec->cgi(), 'CGI', 'cgi() returns a new CGI object');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->cgi(), $dec->cgi(), 'cgi() returns a cached CGI object');
}

{
  my $dec = ClearPress::decorator->new();
  my $cgi = {};
  is($dec->cgi($cgi), $cgi, 'cgi() returns a given cgi object');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->save_session(), undef, 'save_session returns undef');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->username(), q(), 'username returns ""');
}

{
  my $dec = ClearPress::decorator->new();
  is($dec->footer(), from_file(q(footer-1.frag)), 'footer returns default html');
}

{
  my $dec = ClearPress::decorator->new();
  $ENV{'SCRIPT_NAME'} = '/foo';
  is($dec->http_header(), from_file(q(header-2.frag)), 'header w/script_name is ok');
}

sub from_file {
  my $fn = shift;

  open my $fh, q[<], "t/data/rendered/$fn";
  local $RS = undef;
  my $content = <$fh>;
  close $fh;

  return $content;
}

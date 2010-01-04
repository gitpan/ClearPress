#########
# Author:        rmp
# Last Modified: $Date: 2010-01-04 12:41:14 +0000 (Mon, 04 Jan 2010) $ $Author: zerojinx $
# Id:            $Id: 00-critic.t 346 2010-01-04 12:41:14Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-critic.t,v $
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 346 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

if ( not $ENV{TEST_AUTHOR} ) {
  my $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
  plan( skip_all => $msg );
}

eval {
  require Test::Perl::Critic;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Perl::Critic not installed';

} else {
  Test::Perl::Critic->import(
			     -severity => 1,
			     -exclude => [qw(tidy
					     ValuesAndExpressions::ProhibitImplicitNewlines
					     NamingConventions::Capitalization
					     ValuesAndExpressions::RequireConstantVersion)],
			    );
  all_critic_ok();
}

1;

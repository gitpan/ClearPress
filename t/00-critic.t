# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Last Modified: $Date: 2011-10-11 13:39:49 +0100 (Tue, 11 Oct 2011) $ $Author: zerojinx $
# Id:            $Id: 00-critic.t 413 2011-10-11 12:39:49Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-critic.t,v $
# $HeadURL: svn+ssh://zerojinx@svn.code.sf.net/p/clearpress/code/trunk/t/00-critic.t $
#
package critic;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 413 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

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
                                             PodSpelling
					     NamingConventions::Capitalization
					     ValuesAndExpressions::RequireConstantVersion)],
			    );
  all_critic_ok();
}

1;

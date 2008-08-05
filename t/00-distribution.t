#########
# Author:        rmp
# Last Modified: $Date: 2008-08-03 21:30:57 +0100 (Sun, 03 Aug 2008) $ $Author: zerojinx $
# Id:            $Id: 00-distribution.t 237 2008-08-03 20:30:57Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-distribution.t,v $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/branches/prerelease-1.17/t/00-distribution.t $
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 237 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import('not' => 'prereq'); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;

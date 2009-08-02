#########
# Author:        rmp
# Last Modified: $Date: 2009-06-09 20:17:59 +0100 (Tue, 09 Jun 2009) $ $Author: zerojinx $
# Id:            $Id: 00-distribution.t 338 2009-06-09 19:17:59Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-distribution.t,v $
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/branches/prerelease-1.26/t/00-distribution.t $
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 338 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import('not' => 'prereq'); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;

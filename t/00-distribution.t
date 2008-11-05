#########
# Author:        rmp
# Last Modified: $Date: 2008-10-31 13:48:13 +0000 (Fri, 31 Oct 2008) $ $Author: zerojinx $
# Id:            $Id: 00-distribution.t 267 2008-10-31 13:48:13Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-distribution.t,v $
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/branches/prerelease-1.19/t/00-distribution.t $
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 267 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import('not' => 'prereq'); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;

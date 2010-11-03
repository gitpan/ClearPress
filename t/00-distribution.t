#########
# Author:        rmp
# Last Modified: $Date: 2010-11-03 16:19:48 +0000 (Wed, 03 Nov 2010) $ $Author: zerojinx $
# Id:            $Id: 00-distribution.t 390 2010-11-03 16:19:48Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/t/00-distribution.t,v $
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/t/00-distribution.t $
#
package distribution;
use strict;
use warnings;
use Test::More;
use English qw(-no_match_vars);
use lib qw(t); use Net::LDAP;

our $VERSION = do { my @r = (q$Revision: 390 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

eval {
  require Test::Distribution;
};

if($EVAL_ERROR) {
  plan skip_all => 'Test::Distribution not installed';
} else {
  Test::Distribution->import(); # Having issues with Test::Dist seeing my PREREQ_PM :(
}

1;

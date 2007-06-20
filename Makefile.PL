#########
# Author:        rmp
# Last Modified: $Date: 2007-06-20 23:06:30 +0100 (Wed, 20 Jun 2007) $ $Author: zerojinx $
# Id:            $Id: Makefile.PL 4 2007-06-20 22:06:30Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/Makefile.PL,v $
# $HeadURL$
#
package Makefile;
use strict;
use warnings;
use 5.005;
use ExtUtils::MakeMaker;
use English qw(-no_match_vars);

our $VERSION = do { my @r = (q$Revision: 1.2 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

WriteMakefile(
	      'NAME'          => 'ClearPress',
	      'AUTHOR'        => q(Roger Pettett <rmp@sanger.ac.uk>),
	      'VERSION_FROM'  => 'lib/ClearPress/controller.pm',
	      'DISTNAME'      => 'ClearPress',
	      'PREREQ_PM'     => {
				  'DBI'      => 1.51,
				  'English'  => 1.01,
				  'Carp'     => 1.02,
				  'Template' => 2.19,
				 },
	      'dist'          => { COMPRESS => 'gzip', SUFFIX => 'gz', },
	     );

1;

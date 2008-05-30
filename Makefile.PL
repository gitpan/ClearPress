#########
# Author:        rmp
# Last Modified: $Date: 2008-05-31 00:08:14 +0100 (Sat, 31 May 2008) $ $Author: zerojinx $
# Id:            $Id: Makefile.PL 161 2008-05-30 23:08:14Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/Makefile.PL,v $
# $HeadURL: https://zerojinx:@clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/Makefile.PL $
#
package Makefile;
use strict;
use warnings;
use 5.005;
use ExtUtils::MakeMaker;
use English qw(-no_match_vars);
use lib qw(t);

our $VERSION = do { my @r = (q$Revision: 161 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

WriteMakefile(
	      'NAME'          => 'ClearPress',
	      'AUTHOR'        => q(Roger Pettett <rmp@sanger.ac.uk>),
	      'VERSION_FROM'  => 'lib/ClearPress.pm',
	      'DISTNAME'      => 'ClearPress',
	      'PREREQ_PM'     => {
				  'Class::Accessor'     => 0.31,
		                  'Config::IniFiles'    => 2.38,
				  'CGI'                 => 3.20,
				  'DBI'                 => 1.51,
				  'English'             => 1.01,
				  'Carp'                => 1.02,
				  'Template'            => 2.19,
				  'Lingua::EN::Inflect' => 1.89,
				  'IO::Scalar'          => 2.110,
				  'POSIX'               => 1.09,
				 },
#	      'LICENSE'       => 'perl',
	      'dist'          => { COMPRESS => 'gzip', SUFFIX => 'gz', },
	     );

1;

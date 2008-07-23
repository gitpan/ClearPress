#########
# Author:        rmp
# Last Modified: $Date: 2008-07-21 15:57:04 +0100 (Mon, 21 Jul 2008) $ $Author: zerojinx $
# Id:            $Id: Makefile.PL 209 2008-07-21 14:57:04Z zerojinx $
# Source:        $Source: /cvsroot/clearpress/clearpress/Makefile.PL,v $
# $HeadURL: https://clearpress.svn.sourceforge.net/svnroot/clearpress/trunk/Makefile.PL $
#
package Makefile;
use strict;
use warnings;
use 5.005;
use ExtUtils::MakeMaker;
use English qw(-no_match_vars);
use lib qw(t);

our $VERSION = do { my @r = (q$Revision: 209 $ =~ /\d+/mxg); sprintf '%d.'.'%03d' x $#r, @r };

WriteMakefile(
	      'NAME'          => 'ClearPress',
	      'AUTHOR'        => q(Roger Pettett <rmp@sanger.ac.uk>),
	      'VERSION_FROM'  => 'lib/ClearPress.pm',
	      'DISTNAME'      => 'ClearPress',
	      'PREREQ_PM'     => {
				  'Class::Accessor'     => '0.31',
		                  'Config::IniFiles'    => '2.38',
				  'CGI'                 => '3.20',
				  'DBI'                 => '1.51',
				  'English'             => '1.01',
				  'Carp'                => '1.02',
				  'Template'            => '2.19',
				  'Template::Context'   => '2.98',
				  'Lingua::EN::Inflect' => '1.89',
				  'IO::Scalar'          => '2.110',
				  'POSIX'               => '1.09',
				  'XML::TreeBuilder'    => '3.09',  # for testing
				  'Test::More'          => '0.8',   # for testing
				  'Test::Trap'          => '0.1.1', # for testing
				 },
#	      'LICENSE'       => 'perl',
	      'dist'          => { COMPRESS => 'gzip', SUFFIX => 'gz', },
	     );

1;

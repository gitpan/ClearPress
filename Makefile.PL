#########
# Author:        rmp
# Last Modified: $Date: 2007-06-25 09:35:19 +0100 (Mon, 25 Jun 2007) $ $Author: zerojinx $
# Id:            $Id: Makefile.PL 12 2007-06-25 08:35:19Z zerojinx $
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
	      'VERSION_FROM'  => 'lib/ClearPress.pm',
	      'DISTNAME'      => 'ClearPress',
	      'PREREQ_PM'     => {
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

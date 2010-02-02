use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
				 module_name         => 'ClearPress',
				 dist_author         => 'Roger M Pettett <rpettett@cpan.org>',
				 dist_version_from   => 'lib/ClearPress.pm',
				 dist_abstract       => q[ClearPress - Simple, fresh & fruity MVC framework],
				 license             => 'perl',
				 requires            => {
							 'Class::Accessor'     => '0.31',
							 'Config::IniFiles'    => '2.38',
							 'CGI'                 => '3.20',
							 'Class::Singleton'    => '1.4',
							 'DBI'                 => '1.51',
							 'English'             => '1.01',
							 'Carp'                => '1.02',
							 'Template'            => '2.19',
							 'Template::Filters'   => '2.86',
							 'Lingua::EN::Inflect' => '1.89',
							 'IO::Scalar'          => '2.110',
							 'POSIX'               => '1.09',
							 'Readonly'            => '1.03',
							 'XML::Simple'         => '2.18',
							 'HTML::Entities'      => '1.35',
							 'base'                => '2.13',
							 'strict'              => '1.03',
							 'warnings'            => '1.05',
							 'YAML::Tiny'          => '1.36',
							 'Crypt::CBC'          => '2.30',
							 'Crypt::Blowfish'     => '2.10',
							 'MIME::Base64'        => '3.07',
							},
				 recommends          => {
							 'DBD::SQLite'         => '1.14',
							 'DBD::mysql'          => '4.007',
							 'Net::LDAP'           => '0.39',
							 'Crypt::MySQL'        => '0.04',
							 'Digest::MD5'         => '2.39',
							 'Digest::SHA'         => '5.47',
							},
				 build_requires      => {
							 'Test::Distribution'  => '0',
							 'Test::Perl::Critic'  => '0',
							 'XML::TreeBuilder'    => '3.09',
							 'Test::More'          => '0.8',
							 'Test::Trap'          => '0',
							 'Cwd'                 => '3.2701',
							 'File::Spec'          => '3.2701',
							 'CPAN'                => '1.9205',
							 'XML::Simple'         => '2.18',
							 'JSON'                => '2.12',
							 'XML::LibXML'         => '1.66',
							},
				 build_recommends    => {
							 'Test::Distribution'  => '0',
							 'Test::Perl::Critic'  => '0',
							},
				 script_files        => [qw(bin/clearpress)],
				);

$builder->create_build_script();

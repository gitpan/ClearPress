use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
				 module_name         => 'ClearPress',
				 dist_author         => 'Roger M Pettett <rpettett@cpan.org>',
				 dist_version        => do { my ($r) = q$Revision: 291 $ =~ /(\d+)/mx; $r; },
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
							 'Lingua::EN::Inflect' => '1.89',
							 'IO::Scalar'          => '2.110',
							 'POSIX'               => '1.09',
							 'Readonly'            => '1.03',
							 'XML::Simple'         => '2.18',
							},
				 recommends          => {
							 'DBD::SQLite'         => '1.14',
							 'DBD::mysql'          => '4.007',
							},
				 build_requires      => {
							 'Test::Distribution'  => '0',
							 'Test::Perl::Critic'  => '0',
							 'XML::TreeBuilder'    => '3.09',
							 'Test::More'          => '0.8',
							 'Test::Trap'          => '0.1.1',
							 'Cwd'                 => '3.2701',
							 'File::Spec'          => '3.2701',
							 'CPAN'                => '1.9205',
							 'XML::Simple'         => '2.18',
							 'JSON'                => '2.12',
							},
				 build_recommends    => {
							 'Test::Distribution' => '0',
							 'Test::Perl::Critic' => '0',
							},
				 create_makefile_pl  => 'passthrough',
				 script_files        => [qw(bin/clearpress)],
				);

$builder->create_build_script();

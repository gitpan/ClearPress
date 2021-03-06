# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
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
							 'Class::Accessor'      => '0.31',
							 'Config::IniFiles'     => '2.38',
							 'CGI'                  => '3.20',
							 'DBI'                  => '1.51',
							 'English'              => '1.01',
							 'Carp'                 => '1.02',
							 'Template'             => '2.19',
							 'Template::Filters'    => '2.86',
							 'Lingua::EN::Inflect'  => '1.89',
                                                         'IO::Capture'          => '0.05',
							 'IO::Scalar'           => '2.110',
							 'POSIX'                => '1.09',
							 'Readonly'             => '1.03',
							 'XML::Simple'          => '2.18',
							 'HTML::Entities'       => '1.35',
                                                         'HTTP::Server::Simple' => '0.44',
							 'base'                 => '2.13',
							 'strict'               => '1.03',
							 'warnings'             => '1.05',
							 'YAML::Tiny'           => '1.36',
							 'Crypt::CBC'           => '2.30',
							 'Crypt::Blowfish'      => '2.10',
							 'MIME::Base64'         => '3.07',
							},
				 recommends          => {
							 'Crypt::MySQL'         => '0.04',
							 'DBD::SQLite'          => '1.14',
							 'DBD::mysql'           => '4.007',
							 'Digest::MD5'          => '2.39',
							 'Digest::SHA'          => '5.47',
							 'Net::LDAP'            => '0.39',
							},
				 build_requires      => {
							 'CPAN'                 => '1.9205',
							 'Cwd'                  => '3.2701',
							 'File::Copy'           => '2.09',
							 'File::Path'           => '2.07_02',
							 'File::Spec'           => '3.2701',
                                                         'File::Temp'           => '0.22',
							 'JSON'                 => '2.12',
							 'Test::More'           => '0.8',
							 'Test::Trap'           => '0',
							 'XML::LibXML'          => '1.66',
							 'XML::Simple'          => '2.18',
							 'XML::TreeBuilder'     => '3.09',
							},
				 build_recommends    => {
                                                         'Spreadsheet::ParseExcel' => '0.59',
							 'Test::Distribution'      => '0',
							 'Test::Perl::Critic'      => '0',
							},
                                 configure_requires  => {
                                                         'Module::Build'           => '0.38',
                                                        },
				 script_files        => [qw(bin/clearpress)],
				);

$builder->create_build_script();

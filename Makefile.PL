use strict;
use warnings;

use ExtUtils::MakeMaker;

(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

my %build_requires = (
    'Test::More'        => 0,
);

my %requires = (
    'Moo'                       => 0.009013,
    'File::Path'                => 0,
    'File::Basename'            => 0,
    'Module::Metadata'          => 0,
    'Module::Runtime'           => 0,
    'Data::YAML::Writer'        => 0,
    'Object::Remote'            => 0,
    'Object::Remote::Future'    => 0,
    'Config::General'           => 0,
    'Pod::Usage'                => 0,
    'Getopt::Long'              => 0,
    'Digest::SHA'               => 0,
    'strictures'                => 1,
    'IPC::Run'                  => 0,
    'Capture::Tiny'             => 0.12, # capture_stderr
    'File::Tree::Snapshot'      => 0,
    'Object::Remote'            => 0,
    'JSON::Diffable'            => 0,
);

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $mymeta_works = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5707 };
my $mymeta = do { no warnings; $ExtUtils::MakeMaker::VERSION >= 6.5702 };

WriteMakefile(
  NAME => 'System-Introspector',
  VERSION_FROM => 'lib/System/Introspector.pm',
  PREREQ_PM => {
    %requires,
    ($mymeta_works ? () : (%build_requires)),
  },
  ($mymeta_works
    ? ( # BUILD_REQUIRES makes MYMETA right, requires stops META being wrong
        BUILD_REQUIRES => \%build_requires,
        META_ADD => { requires => \%requires }
      )
    : ( # META_ADD both to get META right - only Makefile written
        META_ADD => {
          requires => \%requires,
          build_requires => \%build_requires,
        }
      )
  ),
  ($mymeta && !$mymeta_works ? (NO_MYMETA => 1) : ()),
  LICENSE => 'perl',
  EXE_FILES => ['bin/system-introspector'],
);;

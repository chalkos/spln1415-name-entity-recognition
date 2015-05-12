use 5.020001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
  return <<'END_OF_RULE';
application:
	perl -I ./lib app/Application.pl
END_OF_RULE
}

WriteMakefile(
    NAME              => 'NameEntityRecognition',
    VERSION_FROM      => 'lib/NameEntityRecognition.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/NameEntityRecognition.pm', # retrieve abstract from module
    AUTHOR            => 'B. Ferreira <chalkos@chalkos.net>, M. Pinto <mcpinto98@gmail.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);

use 5.020001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
  return q{
application:
	perl -I ./lib -I ./lib/NER -I ./lib/NER/Recognizers app/Application.pl

alldoc: README.pod README.html

cleandoc:
	rm -f README.pod
	rm -f README.html

README.pod: lib/NER.pm lib/NER/Logger.pm lib/NER/Recognizer.pm lib/NER/Recognizers/Base.pm lib/NER/Recognizers/Acronym.pm lib/NER/Recognizers/Date.pm lib/NER/Recognizers/Geography.pm lib/NER/Recognizers/Location.pm lib/NER/Recognizers/Organization.pm lib/NER/Recognizers/Person.pm lib/NER/Recognizers/Role.pm
	podselect -section "!AUTHOR|COPYRIGHT AND LICENSE" $? > README.pod
	podselect -section "AUTHOR|COPYRIGHT AND LICENSE" $< >> README.pod

README.html: README.pod
	cat $< | pod2html --header --outfile=$@

};
}

WriteMakefile(
    NAME              => 'NER',
    VERSION_FROM      => 'lib/NER.pm', # finds $VERSION, requires EU::MM from perl >= 5.5
    PREREQ_PM         => {}, # e.g., Module::Name => 1.1
    ABSTRACT_FROM     => 'lib/NER.pm', # retrieve abstract from module
    AUTHOR            => 'B. Ferreira <chalkos@chalkos.net>, M. Pinto <mcpinto98@gmail.com>',
    #LICENSE           => 'perl',
    #Value must be from legacy list of licenses here
    #http://search.cpan.org/perldoc?Module%3A%3ABuild%3A%3AAPI
);

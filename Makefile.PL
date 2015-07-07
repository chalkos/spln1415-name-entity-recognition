use 5.020001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
  return <<'END_OF_RULE';
application:
	perl -I ./lib -I ./lib/NER -I ./lib/NER/Recognizers app/Application.pl
htmlreport: htmlreport/NER.html htmlreport/NER_Logger.html htmlreport/NER_Recognizer.html htmlreport/NER_Recognizers_Acronym.html htmlreport/NER_Recognizers_Base.html htmlreport/NER_Recognizers_Date.html htmlreport/NER_Recognizers_Geography.html htmlreport/NER_Recognizers_Location.html htmlreport/NER_Recognizers_Organization.html htmlreport/NER_Recognizers_Person.html htmlreport/NER_Recognizers_Role.html

htmlreportclean:
	rm -f htmlreport/*.html

htmlreport/NER.html: lib/NER.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Logger.html: lib/NER/Logger.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizer.html: lib/NER/Recognizer.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizers_Acronym.html: lib/NER/Recognizers/Acronym.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizers_Base.html: lib/NER/Recognizers/Base.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizers_Date.html: lib/NER/Recognizers/Date.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizers_Geography.html: lib/NER/Recognizers/Geography.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizers_Location.html: lib/NER/Recognizers/Location.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizers_Organization.html: lib/NER/Recognizers/Organization.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizers_Person.html: lib/NER/Recognizers/Person.pm
	podselect $< | pod2html --header --outfile=$@
htmlreport/NER_Recognizers_Role.html: lib/NER/Recognizers/Role.pm
	podselect $< | pod2html --header --outfile=$@

END_OF_RULE
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

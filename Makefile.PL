use 5.020001;
use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.

sub MY::postamble {
  my $rule =
    "\t".
    'podselect $< | pod2html --header --outfile=$@'.
    "\n";

  return q{
application:
	perl -I ./lib -I ./lib/NER -I ./lib/NER/Recognizers app/Application.pl

alldoc: readmeclean htmlreportclean README.pod htmlreport

README.pod: lib/NER.pm lib/NER/Logger.pm lib/NER/Recognizer.pm lib/NER/Recognizers/Acronym.pm lib/NER/Recognizers/Base.pm lib/NER/Recognizers/Date.pm lib/NER/Recognizers/Geography.pm lib/NER/Recognizers/Location.pm lib/NER/Recognizers/Organization.pm lib/NER/Recognizers/Person.pm lib/NER/Recognizers/Role.pm
	podselect -section "!AUTHOR|COPYRIGHT AND LICENSE" $? > README.pod
	podselect -section "AUTHOR|COPYRIGHT AND LICENSE" $< >> README.pod

readmeclean:
	rm -f README.pod

htmlreport: htmlreport/all.html htmlreport/NER.html htmlreport/NER_Logger.html htmlreport/NER_Recognizer.html htmlreport/NER_Recognizers_Acronym.html htmlreport/NER_Recognizers_Base.html htmlreport/NER_Recognizers_Date.html htmlreport/NER_Recognizers_Geography.html htmlreport/NER_Recognizers_Location.html htmlreport/NER_Recognizers_Organization.html htmlreport/NER_Recognizers_Person.html htmlreport/NER_Recognizers_Role.html

htmlreportclean:
	rm -f htmlreport/*.html

htmlreport/all.html: README.pod
}.$rule.q{
htmlreport/NER.html: lib/NER.pm
}.$rule.q{
htmlreport/NER_Logger.html: lib/NER/Logger.pm
}.$rule.q{
htmlreport/NER_Recognizer.html: lib/NER/Recognizer.pm
}.$rule.q{
htmlreport/NER_Recognizers_Acronym.html: lib/NER/Recognizers/Acronym.pm
}.$rule.q{
htmlreport/NER_Recognizers_Base.html: lib/NER/Recognizers/Base.pm
}.$rule.q{
htmlreport/NER_Recognizers_Date.html: lib/NER/Recognizers/Date.pm
}.$rule.q{
htmlreport/NER_Recognizers_Geography.html: lib/NER/Recognizers/Geography.pm
}.$rule.q{
htmlreport/NER_Recognizers_Location.html: lib/NER/Recognizers/Location.pm
}.$rule.q{
htmlreport/NER_Recognizers_Organization.html: lib/NER/Recognizers/Organization.pm
}.$rule.q{
htmlreport/NER_Recognizers_Person.html: lib/NER/Recognizers/Person.pm
}.$rule.q{
htmlreport/NER_Recognizers_Role.html: lib/NER/Recognizers/Role.pm
}.$rule.q{

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

package NER::Logger;

use 5.020001;
use strict;
use warnings;
use utf8::all;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(TRACE);

# comment the print line to suppress TRACE messages
sub TRACE{
  #print STDERR (shift);
}

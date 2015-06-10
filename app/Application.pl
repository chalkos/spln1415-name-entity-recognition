use strict;
use Data::Dumper;
use utf8::all;
use NameEntityRecognition;

use YAML ('LoadFile');

use Lingua::Jspell;


sub readYAML {
  my $filename = shift;

  return LoadFile($filename);
}

my $nomes = readYAML('app/nomes.yaml');
my $taxonomias = readYAML('app/taxonomia.yaml');

print Dumper $taxonomias;


print "########\n";

my $dict = Lingua::Jspell->new( "port");

print "--- rad:\n" . Dumper($dict->rad("gatinho"));
print "--- fea:\n" . Dumper($dict->fea("gatinho"));
print "--- der:\n" . Dumper($dict->der("gato"));
print "--- flags:\n" . Dumper($dict->flags("gato"));

use strict;
use Data::Dumper;
use utf8::all;
use NER;
use Lingua::Jspell;

use YAML ('LoadFile');

sub readYAML {
  my $filename = shift;

  return LoadFile($filename);
}

my $nomes = readYAML('app/nomes.yaml');
my $taxonomias = readYAML('app/taxonomia.yaml');
my $noticia = 'app/noticia.txt';

my $recognizer = NER->new($nomes,$taxonomias);

$recognizer->recognize_file($noticia);

print Dumper $recognizer->entities;


# print "########\n";

# my $dict = Lingua::Jspell->new( "port");

# print "--- rad:\n" . Dumper($dict->rad("gatinho"));
# print "--- fea:\n" . Dumper($dict->fea("gatinho"));
# print "--- der:\n" . Dumper($dict->der("gato"));
# print "--- flags:\n" . Dumper($dict->flags("gato"));

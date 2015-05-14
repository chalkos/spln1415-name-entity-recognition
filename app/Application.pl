use strict;
use Data::Dumper;
use utf8::all;
use NameEntityRecognition;

use YAML ('LoadFile');

sub readYAML {
  my $filename = shift;

  return LoadFile($filename);
}

my $nomes = readYAML('app/nomes.yaml');
my $taxonomias = readYAML('app/taxonomia.yaml');

print Dumper $taxonomias;

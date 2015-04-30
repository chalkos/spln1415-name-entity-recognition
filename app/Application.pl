use strict;
use Data::Dumper;
use NameEntityRecognition;

use YAML ('LoadFile');

sub readYAML {
  my $filename = shift;

  my $cena = LoadFile($filename);
  print Dumper($cena);
}


readYAML('app/taxonomia.yaml');

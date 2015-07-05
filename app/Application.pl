use strict;
use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use utf8::all;
use NER;
use Lingua::Jspell;
use YAML ('LoadFile');

sub readYAML {
  my $filename = shift;
  return LoadFile($filename);
}

# input
my $nomes = readYAML('app/nomes.yaml');
my $taxonomias = readYAML('app/taxonomia.yaml');
my $noticia = 'app/noticia.txt';

# reconhecimento em 3 passos: inicializar, reconhecer, obter resultados
my $recognizer = NER->new($nomes,$taxonomias);
$recognizer->recognize_file($noticia);
my $entities = $recognizer->entities;

# formato de output
# ENTIDADE:
#    RELACAO: VALOR
#    RELACAO: VALOR
#    (...)
# (...)
my @sortedEntities = sort { "\L$a" cmp "\L$b" } keys %$entities;
foreach my $entity (@sortedEntities) {
  print "$entity:\n";
  foreach my $relation (sort keys %{$entities->{$entity}}) {
    my $values = $entities->{$entity}{$relation};
    foreach my $value (@$values) {
      print "   $relation: $value\n";
    }
  }
}

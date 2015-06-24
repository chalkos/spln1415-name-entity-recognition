package NER::Recognizers::Base;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

use List::Util qw(sum);
use NER qw(search_tree);

######################################
# todas as subrotinas deste módulo são usadas
# em todos os outros módulos NER::Recognizers::*

sub new{
  my ($class,$names,$taxonomy,$entities) = @_;
  my $self = bless {
    'name' => $names,
    'taxo' => $taxonomy,
    'enti' => $entities,
    'dict' => Lingua::Jspell->new("port"),
    }, $class;

  return $self;
}

sub analyse {
  my ($self, $text) = @_;

  my @results = $self->runAll($text);

  return sum(@results) / (scalar @results);
}

# subrotinas que devem ser definidas nos módulos que herdarem deste:
#
# runAll($str) -> dá os valores de certeza das várias análises. Valores
#     de 0 a 100, sendo que 0 é «You know nothing, Jon Snow» e 100 é
#     «Eu nunca me engano e raramente tenho dúvidas»

1;

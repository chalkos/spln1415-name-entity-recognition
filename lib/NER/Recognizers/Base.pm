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
  my ($class,$names,$taxonomy,$entities,$more) = @_;

  my $self = bless {
    'name' => $names,
    'taxo' => $taxonomy,
    'enti' => $entities,
    'dict' => Lingua::Jspell->new("port"),
    'more' => $more,
    }, $class;

  return $self;
}

sub analyse {
  my ($self, $text, $original) = @_;

  my @results = $self->runAll($text, $original);
  my $zeroes = scalar grep {$_ == 0} @results;
  my $count = (scalar @results)-$zeroes;

  return 0 if($count == 0);
  return sum(@results) / $count;
}

# obter o objecto do tipo NER::Recognizer que criou este recognizer
sub set_parent_recognizer {
  my ($self,$parent) = @_;
  $self->{parent} = $parent;
}

sub re_recognize {
  my ($self,$text) = @_;

  if( !defined $self->{parent} ){
    die( "method re_recognize called but no parent recognizer defined." );
  }

  $self->{parent}->recognize($text);
}

# subrotinas que devem ser definidas nos módulos que herdarem deste:
#
# runAll($str) -> dá os valores de certeza das várias análises. Valores
#     de 0 a 100, sendo que 0 é «You know nothing, Jon Snow» e 100 é
#     «Eu nunca me engano e raramente tenho dúvidas»

1;

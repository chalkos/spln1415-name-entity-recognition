package NER::Recognizer;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

use NER::Recognizers::Person;
use NER::Recognizers::Location;
use NER::Recognizers::Organization;

######################################

sub new{
  my ($class,$names,$taxonomy,$entities) = @_;
  my $self = bless {
    'name' => $names,
    'taxo' => $taxonomy,
    'rPerson' => NER::Recognizers::Person->new($names,$taxonomy,$entities),
    'rLocation' => NER::Recognizers::Location->new($names,$taxonomy,$entities),
    'rOrganization' => NER::Recognizers::Organization->new($names,$taxonomy,$entities),
    }, $class;

  return $self;
}

sub recognize {
  my ($self,$text) = @_;

  # Maiusculas e minusculas não são suficientemente fiáveis,
  # por isso usar sempre minusculas
  my $original = $text;
  $text = lc($text);

  # obter os niveis de confiança
  my @confLvls = (
    { type=> 'person',
      lvl => $self->{rPerson}->analyse($text)},
    { type=> 'location',
      lvl => $self->{rLocation}->analyse($text)},
    { type=> 'organization',
      lvl => $self->{rOrganization}->analyse($text)},
  );

  # ordenar por ordem decrescente de niveis de confiança
  my @sortedLvls = sort { $b->{lvl} <=> $a->{lvl} } @confLvls;

  print STDERR 'REC: "' . $text . '" is ' . $sortedLvls[0]->{type} .
    '(' . $sortedLvls[0]->{lvl}.'%) or ' . $sortedLvls[1]->{type} .
    '(' . $sortedLvls[1]->{lvl}.'%) or ' . $sortedLvls[2]->{type} .
    '(' . $sortedLvls[2]->{lvl}.'%).' . "\n";

  return (
    $sortedLvls[0]->{type}, # o tipo reconhecido
    $sortedLvls[0]->{lvl}, # a confiança no tipo reconhecido
    $sortedLvls[0]->{lvl} - $sortedLvls[1]->{lvl}); # proximidade ao segundo lugar
}

1;

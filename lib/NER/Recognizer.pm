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
use NER::Recognizers::Role;

######################################

sub new{
  my ($class,$names,$taxonomy,$entities,$more) = @_;
  my $self = bless {
    'name' => $names,
    'taxo' => $taxonomy,
    'rPerson' => NER::Recognizers::Person->new($names,$taxonomy,$entities,$more),
    'rLocation' => NER::Recognizers::Location->new($names,$taxonomy,$entities,$more),
    'rOrganization' => NER::Recognizers::Organization->new($names,$taxonomy,$entities,$more),
    'rRole' => NER::Recognizers::Role->new($names,$taxonomy,$entities,$more),
    }, $class;

  $self->{rPerson}->set_parent_recognizer($self);

  return $self;
}

sub recognize {
  my $self = shift;
  my $text = shift;

  # Maiusculas e minusculas não são suficientemente fiáveis,
  # por isso usar sempre minusculas
  my $original = $text;
  $text = lc($text);

  # obter os niveis de confiança para todos os recognizers
  my %check = (
    'person' => 'rPerson',
    'location' => 'rLocation',
    'organization' => 'rOrganization',
    'role' => 'rRole',
  );

  my @confLvls;
  foreach my $key (keys %check) {
    push @confLvls, {type=>$key, lvl => $self->{$check{$key}}->analyse($text)};
  }

  # ordenar por ordem decrescente de niveis de confiança
  my @sortedLvls = sort { $b->{lvl} <=> $a->{lvl} } @confLvls;

  if( $sortedLvls[0]->{lvl} >= 40 ){
    print STDERR 'REC: "' . $text . '" is ' . $sortedLvls[0]->{type} .
      '(' . $sortedLvls[0]->{lvl}.'%) or ' . $sortedLvls[1]->{type} .
      '(' . $sortedLvls[1]->{lvl}.'%) or ' . $sortedLvls[2]->{type} .
      '(' . $sortedLvls[2]->{lvl}.'%).' . "\n";
  }

  return (
    $sortedLvls[0]->{type}, # o tipo reconhecido
    $sortedLvls[0]->{lvl}, # a confiança no tipo reconhecido
    $sortedLvls[0]->{lvl} - $sortedLvls[1]->{lvl}); # proximidade ao segundo lugar
}

1;

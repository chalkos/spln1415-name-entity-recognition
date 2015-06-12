package NER::Recognizer;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
use Lingua::Jspell;

use NER::Recognizers::Person;
use NER::Recognizers::Location;

######################################

sub new{
  my ($class,$names,$taxonomy) = @_;
  my $self = bless {
    'name' => $names,
    'taxo' => $taxonomy,
    'rPerson' => NER::Recognizers::Person->new($names,$taxonomy),
    'rLocation' => NER::Recognizers::Location->new($names,$taxonomy),
    }, $class;

  return $self;
}

sub recognize {
  my ($self,$text) = @_;

  # Maiusculas e minusculas não são suficientemente fiáveis,
  # por isso usar sempre minusculas
  $text = lc($text);

  # obter os niveis de confiança
  my @confLvls = (
    { type=> 'person',
      lvl => $self->{rPerson}->analyse($text)},
    { type=> 'location',
      lvl => $self->{rLocation}->analyse($text)},
  );

  # ordenar por ordem decrescente de niveis de confiança
  my @sortedLvls = sort { $b->{lvl} <=> $a->{lvl} } @confLvls;

  return (
    $sortedLvls[0]->{type}, # o tipo reconhecido
    $sortedLvls[0]->{lvl}, # a confiança no tipo reconhecido
    $sortedLvls[0]->{lvl} - $sortedLvls[1]->{lvl}); # proximidade ao segundo lugar
}

###################################
# creates subroutines like:
# is_a_person
# is_a_location
# etc..
foreach my $thing (qw{person location}) {
  eval qq/
    sub is_a_${thing}{
      my (\$self,\$text) = \@_;
      my (\$type) = \$self->recognize(\$text);
      return \$type eq '$thing';
    }
  /;
  print STDERR $@ if ($@);
}

1;

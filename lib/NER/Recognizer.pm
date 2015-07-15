package NER::Recognizer;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

use NER::Logger;

use NER::Recognizers::Person;
use NER::Recognizers::Location;
use NER::Recognizers::Organization;
use NER::Recognizers::Role;
use NER::Recognizers::Date;
use NER::Recognizers::Geography;
use NER::Recognizers::Acronym;

######################################
sub new{
  my ($class,$names,$taxonomy,$entities,$jspell,$more) = @_;
  my $self = bless {
    'name' => $names,
    'taxo' => $taxonomy,
    'rPerson' => NER::Recognizers::Person->new($names,$taxonomy,$entities,$jspell,$more),
    'rLocation' => NER::Recognizers::Location->new($names,$taxonomy,$entities,$jspell,$more),
    'rOrganization' => NER::Recognizers::Organization->new($names,$taxonomy,$entities,$jspell,$more),
    'rRole' => NER::Recognizers::Role->new($names,$taxonomy,$entities,$jspell,$more),
    'rDate' => NER::Recognizers::Date->new($names,$taxonomy,$entities,$jspell,$more),
    'rGeography' => NER::Recognizers::Geography->new($names,$taxonomy,$entities,$jspell,$more),
    'rAcronym' => NER::Recognizers::Acronym->new($names,$taxonomy,$entities,$jspell,$more),
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
    'date' => 'rDate',
    'geography' => 'rGeography',
    'acronym' => 'rAcronym',
  );

  my @confLvls;
  foreach my $key (keys %check) {
    push @confLvls, {type=>$key, lvl => $self->{$check{$key}}->analyse($text,$original)};
  }

  # ordenar por ordem decrescente de niveis de confiança
  my @sortedLvls = sort { $b->{lvl} <=> $a->{lvl} } @confLvls;

  if( $sortedLvls[0]->{lvl} >= 40 ){
    TRACE('REC: "' . $text . '" is ' . $sortedLvls[0]->{type} .
      '(' . $sortedLvls[0]->{lvl}.'%) or ' . $sortedLvls[1]->{type} .
      '(' . $sortedLvls[1]->{lvl}.'%) or ' . $sortedLvls[2]->{type} .
      '(' . $sortedLvls[2]->{lvl}.'%).' . "\n");
  }

  return (
    $sortedLvls[0]->{type}, # o tipo reconhecido
    $sortedLvls[0]->{lvl}, # a confiança no tipo reconhecido
    $sortedLvls[0]->{lvl} - $sortedLvls[1]->{lvl}); # proximidade ao segundo lugar (margem)
}

1;
__END__

=encoding utf8

=head1 === NER::Recognizer ===

NER::Recognizer - Sub-módulo de reconhecimento de entidades usando todos os reconhecedores conhecidos.

=head1 SINOPSE

  my $recognizer = NER::Recognizer->new($names,$taxonomy,$entities);
  my ($type, $trust, $margin) = $recognizer->recognize($possible_entity);

  if( $trust > 40 && $margin > 30 ){
    print "I'm sure it's a $type.\n";
  }elsif($trust > 40 && $margin > 10){
    print "It's probably a $type.\n";
  }elsif($trust > 40){
    print "I'm not sure, but I think it's a $type...\n";
  }else{
    print "I don't think that's an entity.\n";
  }

=head1 DESCRIÇÃO

Este módulo usa todos os C<NER::Recognizers::*> (incluindo, de forma indirecta o C<NER::Recognizers::Base>) para tentar identificar o tipo de uma possível entidade.

=head1 SUBROTINAS

=head2 SUBROTINAS DE INSTÂNCIA

=head3 new

Recebe como argumentos:

=over

=item 1. os L<nomes|/"ESTRUTURA-DE-NOMES">;

=item 2. a L<taxonomia|/"ESTRUTURA-DA-TAXONOMIA">;

=item 3. a L<estrutura de entidades reconhecidas|/"ESTRUTURA-DE-ENTIDADES-RECONHECIDAS"> (preferencialmente a mesma que é usada pelo NER, para estar sempre actualizada);

=item 4. o dicionário jspell a utilizar pelos reconhecedores;

=item 5. uma hash com alguns valores adicionais específicos para alguns reconhecedores.

=back

Inicializa instâncias de todos os recognizers e passa uma referência para sí próprio ao L<NER::Recognizers::Person|/"NER::Recognizers::Person"> usando L<set_parent_recognizer|/"set_parent_recognizer">.

=head3 recognize

Recebe uma possível entidade.

Usa todos os reconhecedores para reconhecer a entidade. Caso algum deles consiga identificar a entidade a subrotina devolve vários valores para permitir a tomada de decisão de aceitar ou não o reconhecimento.

Valor de retorno:

=over

=item 1. O tipo reconhecido (string);

=item 2. O grau de confiança do tipo reconhecido;

=item 3. Margem entre o grau de confiança do tipo seleccionado e do tipo com maior grau de confiança imediatamente a seguir.

=back

=head1 AUTORES

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

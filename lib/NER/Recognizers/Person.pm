package NER::Recognizers::Person;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

use NER::Logger;
use List::Util qw(sum max);

require NER::Recognizers::Base;
our @ISA = qw(NER::Recognizers::Base);

######################################

sub runAll {
  my ($self,$str,$original) = @_;

  return (
    $self->palavras_individuais($str),
    $self->fim_de_um_nome_ja_existente($original),
    $self->inicio_de_str_corresponde_a_algo_que_nao_nome($original),
  );
}

sub inicio_de_str_corresponde_a_algo_que_nao_nome {
  my ($self,$str) = @_;
  my @partes = split ' ', $str;

  my $offset = 0;
  my @substrs;

  # evitar entrar em ciclo
  my (undef,undef,undef,$fun) = caller(5);
  return 0 if( $fun =~ m/::inicio_de_str_corresponde_a_algo_que_nao_nome/ );

  while( ($offset = index($str, ' ', $offset)) != -1 ) {
    push @substrs, substr( $str, 0, $offset );
    $offset++;
  }

  foreach my $substr (@substrs) {
    TRACE("checking \"$substr\"...\n");
    my ($type,$lvl,$diff) = $self->re_recognize($substr);
    if( $lvl >= 40 && $type ne 'person' ){
      TRACE("$substr is not a person!\n");
      my $ret = 100-2*$lvl;
      return 1 if($ret < 1);
      return $ret;
    }
  }
  TRACE("done checking!\n") if( scalar @substrs > 0 );

  return 0;
}

sub fim_de_um_nome_ja_existente{
  my ($self, $str) = @_;

  foreach my $key (keys %{$self->{enti}}) {
    if($key =~ /${str}$/ && grep {$_ eq 'person'} @{$self->{enti}{$key}{tipo}}){
      return 90;
    }
  }
  return 0;
}

sub palavras_individuais {
  my ($self, $str) = @_;

  # remover partes dispensáveis
  $str =~ s/\s(da|de|do|das|dos)\s/ /g;

  my @valores;
  my $count_without_zeroes;
  foreach my $palavra (split /\s/,$str) {
    my @vals_pal = (
      $self->palavras_individuais_hash_nomes($palavra),
      $self->palavras_individuais_nome_de_pessoa_portugues_ou_estrangeiro($palavra),
      #$self->palavras_individuais_localidade($palavra),
    );

    $count_without_zeroes = (scalar @vals_pal)-(scalar grep {$_ == 0} @vals_pal);

    if( $count_without_zeroes != 0 ){
      push @valores, sum(@vals_pal) / $count_without_zeroes;
    }
  }

  $count_without_zeroes = (scalar @valores)-(scalar grep {$_ == 0} @valores);

  return 0 if($count_without_zeroes == 0);
  return sum(@valores) / $count_without_zeroes;
}

sub palavras_individuais_hash_nomes {
  my ($self, $palavra) = @_;
  return defined($self->{name}->{ucfirst $palavra}) ? 70 : 0;
}

sub palavras_individuais_nome_de_pessoa_portugues_ou_estrangeiro {
  my ($self, $palavra) = @_;

  my @fea = $self->{dict}->fea($palavra);
  foreach my $analise ( @fea ) {
    if( $analise->{CAT} =~ /np/ && defined($analise->{SEM}) && $analise->{SEM} =~ /^(p|p1)$/ ){
      return 70;
    }
  }
  return 0;
}

#sub palavras_individuais_localidade {
#  my ($self, $palavra) = @_;
#
#  my @fea = $self->{dict}->fea($palavra);
#  foreach my $analise ( @fea ) {
#    if( $analise->{CAT} =~ /np/ && defined($analise->{SEM}) && $analise->{SEM} =~ /^(cid|ter|country)$/ ){
#      return 0;
#    }
#  }
#  return 0;
#}

1;
__END__

=encoding utf8

=head1 === NER::Recognizers::Person ===

NER::Recognizers::Person - Sub-módulo de reconhecimento de nomes de pessoas.

=head1 SINOPSE

  my $recognizer = NER::Recognizers::Person->new($names,$taxonomy,$entities);
  my $confidence = $recognizer->analyse($normalized_text, $original_text);

=head1 DESCRIÇÃO

Este módulo herda todas as subrotinas definidas no L<NER::Recognizers::Base|/"NER::Recognizers::Base">, tem uma implementação específica da subrotina L<runAll|/"runAll"> e subrotinas específicas para identificar entidades do tipo 'C<person>'.

TODO: não esquecer de escrever sobre a forma como este modulo usa o re_recognize

=head1 SUBROTINAS

=head2 SUBROTINAS PARA OBTER O GRAU DE CONFIANÇA

=head3 palavras_individuais

Recebe como argumento a possível entidade (string).

Executa algumas subrotinas especializadas para obter resultados com base em palavras individuais que existam dentro da string. Todas as subrotinas são executadas para cada palavra. No fim é devolvida a média de todos os valores diferentes de 0 vindos dessas subrotinas mais especializadas.

As subrotinas mais especializadas são
L<palavras_individuais_hash_nomes|/"palavras_individuais_hash_nomes">
L<palavras_individuais_nome_de_pessoa_portugues_ou_estrangeiro|/"palavras_individuais_nome_de_pessoa_portugues_ou_estrangeiro">

=head3 fim_de_um_nome_ja_existente

Recebe uma possível entidade.

Devolve o valor 90 se a possível entidade corresponder ao fim de uma entidade que seja um nome de uma pessoa (porque existe a probabilidade de se estar a referir uma pessoa por um ou mais dos seus apelidos finais). E devolve 0 caso não consiga tirar conclusões.

=head3 inicio_de_str_corresponde_a_algo_que_nao_nome

Recebe uma possível entidade.

Analisa todas as substrings que começam no início da string e são diferentes da string. Para cada uma das substrings tenta reconhecer (usando a instância do L<NER::Recognizer|/"NER::Recognizer"> definida em L<set_parent_recognizer|/"set_parent_recognizer">) algo que não seja um nome com um grau de confiança maior ou igual a 40. Caso seja reconhecida uma nova entidade, esta subrotina devolve um valor entre 1 e 20 (baixando significativamente a média de graus de confiança para o reconhecimento de um nome).

Por exemplo, para "Lisboa António Costa" tem-se as substrings "Lisboa" e "Lisboa António". Ao tentar reconhecer "Lisboa", o reconhecedor identifica uma cidade com um alto grau de confiança, e por isso a subrotina devolve 1.

Se nenhuma das substrings for reconhecida como algo que não seja um nome, a subrotina devolve o valor 0 (para evitar influenciar negativamente o actual grau de confiança).

=head2 SUBROTINAS PARA OBTER O GRAU DE CONFIANÇA PARA PALAVRAS INDIVIDUAIS

=head3 palavras_individuais_hash_nomes

Recebe uma palavra.

Devolve 70 se essa palavra constar na hash de nomes. Caso contrário devolve 0.

=head3 palavras_individuais_nome_de_pessoa_portugues_ou_estrangeiro

Recebe uma palavra.

Devolve 70 se essa palavra for identificada como nome português ou estrangeiro pelo Jspell. Caso contrário devolve 0.

=head1 AUTORES

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

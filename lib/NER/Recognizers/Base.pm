package NER::Recognizers::Base;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

use List::Util qw(sum);

######################################
# todas as subrotinas deste módulo são usadas
# em todos os outros módulos NER::Recognizers::*

sub new{
  my ($class,$names,$taxonomy,$entities,$jspell,$more) = @_;

  my $self = bless {
    'name' => $names,
    'taxo' => $taxonomy,
    'enti' => $entities,
    'dict' => $jspell,
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
__END__

=encoding utf8

=head1 === NER::Recognizers::Base ===

NER::Recognizers::Base - Sub-módulo com partes comuns a todos os NER::Recognizers.

=head1 DESCRIÇÃO

Este módulo é o equivalente a uma classe abstracta de linguagens mais focadas no paradigma orientado a objectos.

São definidas algumas subrotinas às quais todos os outros NER::Recognizers vão ter acesso via C<our @ISA = qw(NER::Recognizers::Base)>.

Cada módulo C<NER::Recognizers::*> à excepção do C<NER::Recognizers::Base> tem obrigatoriamente definida a subrotina L<runAll|/"runAll"> e uma ou mais subrotinas para reconhecimento de características específicas do tipo de entidade tratado pelo C<NER::Recognizers::*>.

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

E cria um novo reconhecedor que tem acesso às informações passadas nos argumentos.

=head3 analyse

Recebe como argumentos:

=over

=item 1. A expressão a reconhecer (normalizado para todas as letras serem minúsculas);

=item 2. A expressão original a reconhecer (sem qualquer modificação);

=back

Chama a subrotina L<runAll|/"runAll"> do módulo de reconhecimento e dá como resultado a média de todos os valores diferentes de zero. O valor devolvido por esta subrotina é, para efeitos práticos, o grau de confiança com que se pode afirmar que a entidade é de um determinado tipo.

=head3 set_parent_recognizer

Recebe um objecto do tipo L<NER::Recognizer|/"NER::Recognizer"> como único argumento.

Deve ser usado caso o reconhecedor precise de usar o L<NER::Recognizer|/"NER::Recognizer">. No estado actual apenas o L<NER::Recognizers::Person|/"NER::Recognizers::Person"> usa esta funcionalidade.

=head3 re_recognize

Recebe uma possível entidade que se quer tentar reconhecer.

É usado caso o reconhecedor precise de usar o L<NER::Recognizer|/"NER::Recognizer">. No estado actual apenas o L<NER::Recognizers::Person|/"NER::Recognizers::Person"> usa esta subrotina.

=head3 runAll

Recebe como argumentos:

=over

=item 1. A expressão a reconhecer (normalizado para todas as letras serem minúsculas);

=item 2. A expressão original a reconhecer (sem qualquer modificação);

=back

Executa todas as subrotinas de reconhecimento para um determinado tipo de entidade e devolve um array dos valores dados por essas subrotinas.

Esta subrotina é usada de forma semelhante a um método I<abstract> em linguagens mais focadas no paradigma orientado a objectos. O módulo C<NER::Recognizers::Base> não a define, mas todos os outros C<NER::Recognizers::*> têm a sua implementação específica desta subrotina.

A documentação desta subrotina foi incluída no C<NER::Recognizers::Base> por ter um funcionamento idêntico em todas as suas implementações, embora todos os C<NER::Recognizers::*> menos o C<NER::Recognizers::Base> a definam.

=head1 AUTORES

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

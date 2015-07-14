package NER::Recognizers::Acronym;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

require NER::Recognizers::Base;
our @ISA = qw(NER::Recognizers::Base);
our @EXPORT_OK = qw(REGEX_ACRONYM);

######################################

our $REGEX_ACRONYM = '\p{Lu}{2,}|(?:\p{Lu}\.){2,}';

sub runAll {
  my ($self,$str,$original) = @_;

  return (
    $self->rec_especificas($original),
  );
}

sub rec_especificas {
  my ($self, $str) = @_;

  return 90 if( $str =~ m/^($REGEX_ACRONYM)$/ );

  return 1;
}

1;
__END__

=encoding utf8

=head1 === NER::Recognizers::Acronym ===

NER::Recognizers::Acronym - Sub-módulo de reconhecimento de acrónimos.

=head1 SINOPSE

  my $recognizer = NER::Recognizers::Acronym->new($names,$taxonomy,$entities);
  my $confidence = $recognizer->analyse($normalized_text, $original_text);

=head1 DESCRIÇÃO

Este módulo herda todas as subrotinas definidas no L<NER::Recognizers::Base|/"NER::Recognizers::Base">, tem uma implementação específica da subrotina L<runAll|/"runAll"> e subrotinas específicas para identificar entidades do tipo 'C<acronym>'.

=head1 VARIÁVEIS GLOBAIS

=head2 EXPORT

Nada é exportado de forma implícita/predefinida.

=head2 EXPORT_OK

=head3 REGEX_ACRONYM

Expressão regular usada para capturar entidades do tipo 'C<acronym>'. A expressão também é usada para verificar se uma possível entidade é do tipo 'C<acronym>'.

=head1 SUBROTINAS

=head2 EXPORT

Nada é exportado de forma implícita/predefinida.

=head2 SUBROTINAS PARA OBTER O GRAU DE CONFIANÇA

=head3 rec_especificas

Recebe a possível entidade.

Devolve 90 se L<REGEX_ACRONYM|/"REGEX_ACRONYM"> fizer I<match> na string da possível entidade. Devolve 1 caso não seja possível fazer I<match>.

=head1 AUTORES

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

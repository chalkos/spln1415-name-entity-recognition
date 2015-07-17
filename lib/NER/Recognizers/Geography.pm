package NER::Recognizers::Geography;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

require NER::Recognizers::Base;
our @ISA = qw(NER::Recognizers::Base);

######################################

sub runAll {
  my ($self,$str) = @_;

  return (
    $self->rec_taxonomia($str),
  );
}

sub rec_taxonomia {
  my ($self, $str) = @_;

  return 0 unless(defined $self->{more}{RW_TAXONOMY_GEOGRAPHY_LHS});

  my $regex = $self->{more}{RW_TAXONOMY_GEOGRAPHY_LHS};

  return 90 if( $str =~ m/^($regex)$/ );

  return 0;
}

1;
__END__

=encoding utf8

=head1 === NER::Recognizers::Geography ===

NER::Recognizers::Geography - Sub-módulo de reconhecimento de elementos geográficos.

=head1 SINOPSE

  my $recognizer = NER::Recognizers::Geography->new($names,$taxonomy,$entities);
  my $confidence = $recognizer->analyse($normalized_text, $original_text);

=head1 DESCRIÇÃO

Este módulo herda todas as subrotinas definidas no L<NER::Recognizers::Base|/"NER::Recognizers::Base">, tem uma implementação específica da subrotina L<runAll|/"runAll"> e subrotinas específicas para identificar entidades do tipo 'C<geography>'.

=head1 SUBROTINAS

=head2 SUBROTINAS PARA OBTER O GRAU DE CONFIANÇA

=head3 rec_taxonomia

Recebe uma possível entidade.

Se na criação da instância se tiver passado uma hash de conteúdos adicionais com uma chave 'C<RW_TAXONOMY_GEOGRAPHY_LHS>', esta é usada como uma expressão regular. Se a string fizer I<match> com a expressão regular, a subrotina devolve o valor 90, caso contrário dá o valor 0.

Se não conseguir obter a expressão regular, a subrotina devolve o valor 0.

A intenção é que a expressão regular seja obtida usando C<L<NER|/"NER">-E<gt>L<taxonomy_to_regex|/"taxonomy_to_regex">($taxonomy, 'geografia')>. Desta forma a expressão regular usada no C<Text::RewriteRules> para capturar possíveis entidades é a mesma que é usada no módulo para identificar entidades desse tipo.

=head1 AUTORES

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

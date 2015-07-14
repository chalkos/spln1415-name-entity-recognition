package NER::Recognizers::Location;

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
    $self->rec_jspell_base($str),
    $self->rec_altas_directas($str),
  );
}

# retira da|de|do|das|dos
# usa o jspell para perceber se as palavras são cidades, terras ou países
# no fim devolve a percentagem (de 0 a 100) de locais em relação ao total de palavras
sub rec_jspell_base {
  my ($self, $str) = @_;

  $str =~ s/\s(da|de|do|das|dos)\s/ /g;

  my ($sim,$nao) = (0,0);

  foreach my $n (split /\s/,$str) {
    my @fea = $self->{dict}->fea($n);
    foreach my $analise ( @fea ) {
      if($analise->{CAT} =~ /np/ && $analise->{SEM} =~ /cid|ter|country/){
        $sim++;
      }else{
        $nao++;
      }
    }
  }

  return 1 if( ($sim+$nao) == 0 );

  my $confianca = $sim / ($sim+$nao) * 100;

  $confianca = $confianca * 1.3;
  #$confianca = 90 if($confianca > 90);
  $confianca = 85 if($confianca > 85);

  return $confianca;
}

sub rec_altas_directas {
  my ($self, $str) = @_;

  my @expReg = (
    qr/^vila nova de /,
    qr/^vila /,
  );

  foreach my $exp (@expReg) {
    return 80 if( $str =~ $exp );
  }

  return 0;
}

1;
__END__

=encoding utf8

=head1 === NER::Recognizers::Location ===

NER::Recognizers::Location - Sub-módulo de reconhecimento de acrónimos.

=head1 SINOPSE

  my $recognizer = NER::Recognizers::Location->new($names,$taxonomy,$entities);
  my $confidence = $recognizer->analyse($normalized_text, $original_text);

=head1 DESCRIÇÃO

Este módulo herda todas as subrotinas definidas no L<NER::Recognizers::Base|/"NER::Recognizers::Base">, tem uma implementação específica da subrotina L<runAll|/"runAll"> e subrotinas específicas para identificar entidades do tipo 'C<location>'.

=head1 SUBROTINAS

=head2 SUBROTINAS PARA OBTER O GRAU DE CONFIANÇA

=head3 rec_jspell_base

TODO

=head3 rec_altas_directas

TODO


=head1 AUTORES

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

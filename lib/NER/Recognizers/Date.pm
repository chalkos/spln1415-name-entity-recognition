package NER::Recognizers::Date;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

require NER::Recognizers::Base;
require Exporter;
our @ISA = qw(NER::Recognizers::Base Exporter);
our @EXPORT_OK = qw(REGEX_DATE REGEX_YEAR);

######################################

our $REGEX_MONTHS_LONG = '([Jj]aneiro|[Ff]evereiro|[Mm]arço|[Aa]bril|[Mm]aio|[Jj]u[nl]ho|[Aa]gosto|[Ss]etembro|[Oo]utubro|[Nn]ovembro|[Dd]ezembro)';
our $REGEX_MONTHS_SHORT = '([Jj]an|[Ff]ev|[Mm]ar|[Aa]br|[Mm]ai|[Jj]u[nl]|[Aa]go|[Ss]et|[Oo]ut|[Nn]ov|[Dd]ez)';
our $REGEX_YEAR = '([0-9]{4}|[0-9]{2})';
our $REGEX_DATE = '('.(join '|',
  # 19 de Setembro de 2003
  # 3 de Out de 98
  '[0-3]?[0-9] de ('.$REGEX_MONTHS_LONG.'|'.$REGEX_MONTHS_SHORT.') de '.$REGEX_YEAR,
  # 19 de Setembro
  # 3 de Out
  '[0-3]?[0-9] de ('.$REGEX_MONTHS_LONG.'|'.$REGEX_MONTHS_SHORT.')',
  # Setembro de 2003
  $REGEX_MONTHS_LONG.' de '.$REGEX_YEAR,
  # (em) 2013
  # (início de) 2010
  #'(?<=(em|de)\s)'.$REGEX_YEAR,
  # 25/12/2013
  # 12-25-2013
  '[0-3]?[0-9][-\/][0-3]?[0-9][-\/]'.$REGEX_YEAR,
  # 2013-12-25
  # 2013/25-12
  $REGEX_YEAR.'[-\/][0-3]?[0-9][-\/][0-3]?[0-9]',
  # Janeiro
  # março
  $REGEX_MONTHS_LONG,
).')';

sub runAll {
  my ($self,$str) = @_;

  return (
    $self->rec_especificas($str),
  );
}

sub rec_especificas {
  my ($self, $str) = @_;

  return 90 if( $str =~ m/$REGEX_DATE/ );
  return 70 if( $str =~ m/$REGEX_YEAR/ );

  return 1;
}

1;
__END__

=encoding utf8

=head1 === NER::Recognizers::Date ===

NER::Recognizers::Date - Sub-módulo de reconhecimento de acrónimos.

=head1 SINOPSE

  my $recognizer = NER::Recognizers::Date->new($names,$taxonomy,$entities);
  my $confidence = $recognizer->analyse($normalized_text, $original_text);

=head1 DESCRIÇÃO

Este módulo herda todas as subrotinas definidas no L<NER::Recognizers::Base|/"NER::Recognizers::Base">, tem uma implementação específica da subrotina L<runAll|/"runAll"> e subrotinas específicas para identificar entidades do tipo 'C<date>'.

=head1 VARIÁVEIS GLOBAIS

=head2 EXPORT

Nada é exportado de forma implícita/predefinida.

=head2 EXPORT_OK

=head3 REGEX_DATE

TODO

=head3 REGEX_YEAR

TODO

=head1 SUBROTINAS

=head2 EXPORT

Nada é exportado de forma implícita/predefinida.

=head2 SUBROTINAS PARA OBTER O GRAU DE CONFIANÇA

=head3 rec_especificas

TODO

=head1 AUTOR

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT E LICENÇA

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

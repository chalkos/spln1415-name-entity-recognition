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

=head1 SUBROTINAS

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

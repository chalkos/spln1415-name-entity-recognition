package NER::Recognizers::Role;

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

  return 0 unless(defined $self->{more}{RW_TAXONOMY_ROLE_LHS});

  my $regex = $self->{more}{RW_TAXONOMY_ROLE_LHS};

  return 90 if( $str =~ m/^($regex)$/ );

  return 0;
}

1;
__END__

=encoding utf8

=head1 === NER::Recognizers::Role ===

NER::Recognizers::Role - Sub-módulo de reconhecimento de acrónimos.

=head1 SINOPSE

  my $recognizer = NER::Recognizers::Role->new($names,$taxonomy,$entities);
  my $confidence = $recognizer->analyse($normalized_text, $original_text);

=head1 DESCRIÇÃO

Este módulo herda todas as subrotinas definidas no L<NER::Recognizers::Base|/"NER::Recognizers::Base">, tem uma implementação específica da subrotina L<runAll|/"runAll"> e subrotinas específicas para identificar entidades do tipo 'C<role>'.

=head1 SUBROTINAS

=head2 SUBROTINAS PARA OBTER O GRAU DE CONFIANÇA

=head3 rec_taxonomia

TODO

=head1 AUTOR

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT E LICENÇA

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

package NER::Logger;

use 5.020001;
use strict;
use warnings;
use utf8::all;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(TRACE);

our $Active = 0;

# comment the print line to suppress TRACE messages
sub TRACE{
  print STDERR (shift) if( $Active );
}

1;
__END__

=encoding utf8

=head1 === NER::Logger ===

NER::Logger - Sub-módulo de output de mensagens de I<debug> usado pelo módulo NER.

=head1 SINOPSE

  use NER::Logger qw(TRACE);

  # enables message output
  NER::Logger::Active = 1;
  TRACE("This text is output to STDERR");

  # disables message output
  NER::Logger::Active = 0;
  TRACE("This text is not output to STDERR");

=head1 DESCRIÇÃO

Este módulo é apenas uma forma rápida de activar/desactivar mensagens de debug (basta apenas mudar a variável).

=head1 SUBROTINAS

=head2 EXPORT

Nada é exportado de forma implícita/predefinida.

=head2 EXPORT_OK

=head3 TRACE

Recebe uma string (preferencialmente apenas uma linha terminada com C<\n>) como argumento e escreve-a no STDERR caso C<$Active> seja verdadeiro.

=head1 VARIÁVEIS GLOBAIS

B<$Active>: Se for falso, nenhum output é gerado quando se chama a subrotina L<TRACE|/"TRACE">.

=head1 AUTORES

  B. Ferreira E<lt>chalkos@chalkos.netE<gt>
  M. Pinto E<lt>mcpinto98@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by B. Ferreira and M. Pinto

This program is free software; licensed under GPL.

=cut

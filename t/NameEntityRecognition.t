# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl NameEntityRecognition.t'

#########################

use strict;
use warnings;
use Cwd;

use Test::More;

# é possível usar o módulo
BEGIN { use_ok('NameEntityRecognition') };
# verificar se os métodos principais estão definidos
#can_ok('NameEntityRecognition', qw(Create));

#########################

sub reconhecer {
  my ($nomes, $taxonomia, $frase) = @_;

  my $fun = NameEntityRecognition::Create('text', $nomes, $taxonomia);

  &$fun($frase);
}


is_deeply( reconhecer({}, {}, "nada de especial"), ['example: nada de especial'], "passando o texto directamente" );

done_testing();

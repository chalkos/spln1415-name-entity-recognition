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
  my ($nomes, $taxonomia, $frase, $use_stdin) = @_;

  my $fun = NameEntityRecognition::Create($nomes, $taxonomia);

  if ($use_stdin) {
    open my $stdin, '<', \ "$frase\n"
      or die "Cannot open STDIN to read from string: $!";
    local *STDIN = $stdin;
    &$fun();
  } else {
    &$fun($frase);
  }
}


is( reconhecer({}, {}, "nada de especial"), {}, "passando o texto directamente" );
is( reconhecer({}, {}, "nada de especial", 1), {}, "passando o texto por STDIN" );

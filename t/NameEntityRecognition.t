# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl NameEntityRecognition.t'

#########################

use strict;
use warnings;
use Cwd;
use utf8::all;

use Test::More;

# é possível usar o módulo
BEGIN { use_ok('NameEntityRecognition') };
# verificar se os métodos principais estão definidos
#can_ok('NameEntityRecognition', qw(Create));

#########################

sub reconhecer {
  my ($nomes, $taxonomia, $frase) = @_;

  my $fun = NameEntityRecognition::CreateRecognizer('text', $nomes, $taxonomia);

  &$fun($frase);
}

sub reconhecer_um {
  shift @{reconhecer(@_)};
}


is_deeply( reconhecer_um({}, {}, "nada de especial"), {_line =>'nada de especial'}, "passando o texto directamente" );

is_deeply( reconhecer_um({}, {}, "o livro \"Uma Página em Branco\", da autoria de José Alberto da Silva dos Santos, vendeu"),
  {
    _line => 'o livro Uma Página em Branco da autoria de José Alberto da Silva dos Santos vendeu',
    'José Alberto da Silva dos Santos' => {is_a => 'name'},
    'Uma Página' => {is_a => 'name'},
    'Branco' => {is_a => 'name'},

  }, "detecta entidade pela capitalização" );

done_testing();

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
can_ok('NameEntityRecognition',
  qw(
    new
    recognize_file
    recognize_file_handle
    recognize_string
    recognize_line
    add_entity
    review_entities
    entities
  ));

isa_ok( NameEntityRecognition->new, 'NameEntityRecognition' );

#########################

#recognize string
sub rstr {
  my ($nomes, $taxonomia, $texto) = @_;

  my $recognizer = NameEntityRecognition->new($nomes, $taxonomia);
  $recognizer->recognize_string($texto);

  return $recognizer->entities;
}


is_deeply( rstr({}, {}, "nada de especial"), {}, "linha sem entidades" );

is_deeply( rstr({}, {},
  "o livro \"Uma Página em Branco\", da autoria de José Alberto Branco da Silva Santos, vendeu"),
  {
    'José Alberto Branco da Silva Santos' => {is_a => 'person'},
  }, "detecta nome de pessoa" );

is_deeply( rstr({}, {},
  "o empresário Hugo Valentim da Silva e Cunha anunciou"),
  {
    'Hugo Valentim da Silva e Cunha' => {is_a => 'person'},
  }, "detecta nome de pessoa" );

done_testing();

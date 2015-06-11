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

#####################################
is_deeply( rstr({}, {},
  "o livro da autoria de José Alberto Branco da Silva Santos, vendeu"),
  {
    'José Alberto Branco da Silva Santos' => {is_a => 'person'},
  }, "detecta nome de pessoa" );

#####################################
is_deeply( rstr({'Guimarães'=>'apelido'}, {},
  "Hugo Guimarães falou... e Guimarães afirmou também.."),
  {
    'Hugo Guimarães' => {is_a => 'person'},
    'Guimarães' => {is_a => 'person'},
  }, "detecta que Guimarães é apelido e não cidade" );

#####################################
is_deeply( rstr({'Guimarães'=>'apelido'}, {},
  "Hugo Maia falou... em Guimarães, Maia afirmou também.."),
  {
    'Hugo Maia' => {is_a => 'person'},
    'Maia' => {is_a => 'person'},
    'Guimarães' => {is_a => 'location'},
  }, "detecta que Guimarães localidade e que Maia não é localidade" );

#####################################
is_deeply( rstr({'Guimarães'=>'apelido'}, {},
  "Joaquim Zworovitch... em Guimarães, Zworovitch depois afirmou"),
  {
    'Joaquim Zworovitch' => {is_a => 'person'},
    'Zworovitch' => {is_a => 'person'},
    'Guimarães' => {is_a => 'location'},
  }, "detecta que Guimarães localidade e que Zworovitch é nome" );

#####################################
is_deeply( rstr({}, {},
  "Desde que o então presidente da Câmara de Lisboa António Costa anunciou, em"),
  {
    'António Costa' => {is_a => 'person', is_also => 'presidente da Câmara de Lisboa'},
    'presidente da Câmara de Lisboa' => {is_a => 'thing'},
    'Lisboa' => {is_a => 'location'},
  }, "detecta uma entidade por estar na taxonomia" );


done_testing();

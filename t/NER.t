# Before 'make install' is performed this script should be runnable with
# 'make test'. After 'make install' it should work as 'perl NER.t'

#########################

use strict;
use warnings;
use Cwd;
use utf8::all;

use Test::More;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

# é possível usar o módulo
BEGIN { use_ok('NER') };
# verificar se os métodos principais estão definidos
can_ok('NER',
  qw(
    new
    recognize_file
    recognize_file_handle
    recognize_string
    recognize_line

    add_entity
    review_entities
    entities

    create_relations
    recognize
    is_in_taxonomy
  ));

#normalize_line
#get_words_from_tree
#taxonomy_to_regex
#search_tree
#debug

isa_ok( NER->new, 'NER' );

#########################

#relations in string
sub rstr {
  my ($nomes, $taxonomia, $texto) = @_;
  my $recognizer = NER->new($nomes, $taxonomia);
  $recognizer->recognize_string($texto);

  my $ents = $recognizer->entities;

  return $ents;
}

#####################################
is_deeply(
  rstr({}, {}, "nada de especial"),
  {},
  "linha sem entidades");

#####################################
is_deeply(
  rstr({}, {nada=>{de=>1, espe=>1}, outracoisa=>{especial=>1}}, "nada de especial"),
  {
    'especial'=>{tipo=>['other']},
    'de'=>{tipo=>['other']},
  },
  "duas entidades reconhecidas mas não identificadas");

#####################################
is_deeply(
  rstr(
    {'Abce' => 'nome','Zbre' => 'apelido'},
    {},
    "o livro da autoria de Abce Zbre, vendeu"),
  {'Abce Zbre' => {tipo=>['person']}},
  "detecta nome de pessoa usando a hash de nomes");

#####################################
is_deeply(
  rstr(
    {},
    {},
    "o livro da autoria de José Alberto Branco da Silva Santos, vendeu"),
  {'José Alberto Branco da Silva Santos' => {tipo=>['person']}},
  "detecta nome de pessoa usando JSpell");

#####################################
is_deeply( rstr({'Guimarães'=>'apelido', 'Maia'=>'apelido'}, {},
  "Hugo Maia falou... em Guimarães, Maia afirmou também.."),
  {
    'Hugo Maia' => {tipo => ['person'], alias=>['Maia']},
    'Maia' => {tipo => ['person'], alias=>['Hugo Maia']},
    'Guimarães' => {tipo => ['location']},
  }, "detecta que Guimarães é localidade e que Maia não é localidade" );

#####################################
is_deeply( rstr({'Guimarães'=>'apelido'}, {},
  "acompanhado por Joaquim Zworovitch e companhia... mais tarde Zworovitch afirmou"),
  {
    'Joaquim Zworovitch' => {tipo => ['person'], alias=>['Zworovitch']},
    'Zworovitch' => {tipo => ['person'], alias=>['Joaquim Zworovitch']},
  }, "detecta que Guimarães localidade e que Zworovitch é nome" );

#####################################
is_deeply( rstr({}, {pessoa=>{politico=>{presidente=>1}}},
  "Desde que o então presidente da Câmara de Lisboa António Costa anunciou, em"),
  {
    'António Costa' => {
      tipo => ['person'],
      'é presidente em' => ['Câmara de Lisboa']
      },
    'Câmara' => {
      tipo => ['organization'],
      'localização' => ['Lisboa']},
    'Lisboa' => {tipo => ['location']},
    'presidente' => {tipo=>['role']}
  }, "Detecta, separa e relaciona correctamente entidades (1)" );

#####################################
is_deeply( rstr({}, {pessoa=>{politico=>{'primeiro ministro'=>1}}},
  "Quando o Primeiro Ministro José Sócrates.."),
  {
    'José Sócrates' => {
      tipo => ['person'],
      role => ['Primeiro Ministro'],
      },
    'Primeiro Ministro' => {tipo=>['role']}
  }, "Detecta, separa e relaciona correctamente entidades (2)" );

#####################################
is_deeply( rstr({}, {pessoa=>{politico=>{'primeiro ministro'=>1}}},
  "Em 09/07/1992 nasceu um rapaz, mais tarde, a 21 de Setembro de 1992 nasceu outro rapaz. O mais velho destes rapazes tem 23 anos, embora ambos tenham nascido em 1992, isto é, no ano de 92."),
  {
    '09/07/1992' => {tipo=>['date']},
    '21 de Setembro de 1992' => {tipo=>['date']},
    '1992' => {tipo=>['date']},
    '92' => {tipo=>['date']},
  }, "Reconhece datas" );

done_testing();

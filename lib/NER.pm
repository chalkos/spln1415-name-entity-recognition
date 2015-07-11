package NER;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Lingua::Jspell;
use Text::RewriteRules;

use NER::Recognizer;
require NER::Recognizers::Date;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;

use NER::Logger;

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw(normalize_line get_words_from_tree taxonomy_to_regex);

our $VERSION = '0.01';

####################################
# Rewrite rules (uses heredoc so syntax
# highlight continues to work for 'normal' perl code)
my $rewrite_rules = << 'REWRITE_RULES_BLOCK';
{no warnings 'redefine';

my $RW_TAXONOMY_ROLE_LHS = $self->{RW_TAXONOMY_ROLE_LHS};
my $RW_TAXONOMY_ORGANIZATION_LHS = $self->{RW_TAXONOMY_ORGANIZATION_LHS};
my $RW_TAXONOMY_GEOGRAPHY_LHS = $self->{RW_TAXONOMY_GEOGRAPHY_LHS};
my $RW_TAXONOMY_OTHER = $self->{RW_TAXONOMY_OTHER};

my $taxoBegin = '(o|a|ao|à|aos|ás)';
my $taxoLink  = 'da|de|do|das|dos|Da|De|Do|Das|Dos';

my $word = '\p{L}+';

################################################
################################################
# RewriteRules bug: ^ não funciona para delimitar inicio de string quando se usa /m. falha sempre
# RewriteRules bug: lookbehinds positivos nao funcionam no inicio da expressão regular (com /m)
RULES/m rewrite_entities
({.*?:.*?})=e=>$1

([Cc][aâ]mara\s[Mm]unicipal)=e=>$RWTEXT!! $self->recognize($1)
([Cc][aâ]mara(?!\s[Ff]otogr))=e=>$RWTEXT!! $self->recognize($1)

([^\p{L}])($NER::Recognizers::Date::REGEX_DATE)(?!\p{L})=e=>$1.$RWTEXT!! $self->recognize($2)
^($NER::Recognizers::Date::REGEX_DATE)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
([^\p{L}])($NER::Recognizers::Date::REGEX_DATE)$=e=>$1.$RWTEXT!! $self->recognize($2)
([^\p{L}](?:no|em) \p{L}+ de|em|ano de) ($NER::Recognizers::Date::REGEX_YEAR)(?!\p{L})=e=>$1.' '.$RWTEXT!! $self->recognize($2)
([^\p{L}](?:no|em) \p{L}+ de|em|ano de) ($NER::Recognizers::Date::REGEX_YEAR)$=e=>$1.' '.$RWTEXT!! $self->recognize($2)

([^\p{L}])($NER::Recognizers::Acronym::REGEX_ACRONYM)(?!\p{L})=e=>$1.$RWTEXT!! $self->recognize($2)
^($NER::Recognizers::Acronym::REGEX_ACRONYM)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
([^\p{L}])($NER::Recognizers::Acronym::REGEX_ACRONYM)$=e=>$1.$RWTEXT!! $self->recognize($2)

(\p{Lu}\p{Ll}+((\s(da|de|do|das|dos|Da|De|Do|Das|Dos)\s|\s)\p{Lu}\p{Ll}+)*)=e=>$RWTEXT!! $self->recognize($1)

([^\p{L}])($RW_TAXONOMY_ROLE_LHS)(?!\p{L})=e=>$1.$RWTEXT!! $self->recognize($2)
^($RW_TAXONOMY_ROLE_LHS)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
([^\p{L}])($RW_TAXONOMY_ROLE_LHS)$=e=>$1.$RWTEXT!! $self->recognize($2)

([^\p{L}])($RW_TAXONOMY_ORGANIZATION_LHS)(?!\p{L})=e=>$1.$RWTEXT!! $self->recognize($2)
^($RW_TAXONOMY_ORGANIZATION_LHS)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
([^\p{L}])($RW_TAXONOMY_ORGANIZATION_LHS)$=e=>$1.$RWTEXT!! $self->recognize($2)

([^\p{L}])($RW_TAXONOMY_GEOGRAPHY_LHS)(?!\p{L})=e=>$1.$RWTEXT!! $self->recognize($2)
^($RW_TAXONOMY_GEOGRAPHY_LHS)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
([^\p{L}])($RW_TAXONOMY_GEOGRAPHY_LHS)$=e=>$1.$RWTEXT!! $self->recognize($2)
ENDRULES

RULES/m other_stuff_from_taxonomy
({.*?:.*?})=e=>$1

([^\p{L}])($RW_TAXONOMY_OTHER)(?!\p{L})=e=>$1.$RWTEXT !! $self->is_in_taxonomy($2)
^($RW_TAXONOMY_OTHER)(?!\p{L})=e=>$RWTEXT !! $self->is_in_taxonomy($1)
([^\p{L}])($RW_TAXONOMY_OTHER)$=e=>$1.$RWTEXT !! $self->is_in_taxonomy($2)
ENDRULES

RULES find_relations
({role:([^\}]*?)} {person:([^\}]*?)})=e=>$1 !! $self->create_relations($3,'role',$2)
({organization:([^\}]*?)} d[aeo] {location:([^\}]*?)})=e=>$1 !! $self->create_relations($2,'localização',$3)
({role:([^\}]*?)} d[aeo] {organization:([^\}]*?)} {person:([^\}]*?)})=e=>$1 !! $self->create_relations($4,'é '.$2.' de',$3,$3,'tem '.$2,$4)
({role:([^\}]*?)} d[aeo] {organization:([^\}]*?)} (d[aeo]) {location:([^\}]*?)} {person:([^\}]*?)})=e=>$1 !! $self->create_relations($6,'é '.$2.' em',$3.' '.$4.' '.$5)
({organization:([^\}]*?)} {acronym:([^\}]*?)})=e=>$1 !! $self->create_relations($3,'refere-se a',$2,$2,'tem acrónimo',$3)
({acronym:([^\}]*?)} {organization:([^\}]*?)})=e=>$1 !! $self->create_relations($2,'refere-se a',$3,$3,'tem acrónimo',$2)
({geography:([^\}]*?)} d[aeo] {location:([^\}]*?)})=e=>$1 !! $self->create_relations($2,'localização',$3)
ENDRULES
################################################
################################################
}
REWRITE_RULES_BLOCK

# o próximo comentário é uma tentativa de corrigir uma inconveniência do rewriterules
# line 98

# variável global com o texto de substituição no right hand side da regra
our $RWTEXT;


####################################
# Methods used by rewrite rules

sub create_relations{
  my $self = shift;

  while (scalar @_) {
    my ($x,$rel,$y) = (shift,shift,shift);
    TRACE("Relacionamento: $x -- $rel -- $y\n");

    $self->add_entity({ $x => { $rel => [$y] } });
  }

  return 0;
}

sub recognize2{
  TRACE("~~~~debug: " . $_[1] . "\n");
  recognize(@_);
}

sub recognize{
  my ($self, $str) = @_;

  my ($tipo, $lvl, $diff) = $self->{recognizer}->recognize($str);

  # se os niveis de confiança não forem suficientes, ignorar
  return 0 if( $lvl < 40 );

  # caso contrário:

  # adicionar à colecção de entidades
  $self->add_entity({
    $str => { tipo => [$tipo] },
  });

  # definir o texto de substituição
  $RWTEXT = '{'.$tipo.':'.$str.'}';

  # incrementar o contador de reescritas com sucesso
  $self->{NUMBER_OF_RECOGNITIONS}++;

  return 1;
}

sub is_in_taxonomy{
  my ($self, $str) = @_;

  $self->add_entity({
    $str => {
      tipo => ['other']
      },
    });

  # definir o texto de substituição
  $RWTEXT = '{other:'.$str.'}';

  # incrementar o contador de reescritas com sucesso
  $self->{NUMBER_OF_RECOGNITIONS}++;

  return 1;
}

####################################
# Object methods

sub new{
  my ($class, $names, $taxonomy, $re_write) = @_;

  $re_write = $rewrite_rules if( !defined $re_write || (defined $re_write && !@$re_write) );

  my $RW_TAXONOMY_ROLE_LHS = taxonomy_to_regex($taxonomy, 'pessoa');
  my $RW_TAXONOMY_ORGANIZATION_LHS = taxonomy_to_regex($taxonomy, 'organização');
  my $RW_TAXONOMY_GEOGRAPHY_LHS = taxonomy_to_regex($taxonomy, 'geografia');

  my $RW_TAXONOMY_OTHER = taxonomy_to_regex($taxonomy,
    grep { $_ ne 'pessoa' && $_ ne 'organização' && $_ ne 'geografia' } (keys %$taxonomy));

  my $entities = {};
  my $self = bless {
    'dict' => Lingua::Jspell->new("port"),
    'names' => $names,
    'taxonomy' => $taxonomy,
    'entities' => $entities, #recognized entities
    'rewrite_rules' => $re_write,
    'recognizer' => NER::Recognizer->new($names, $taxonomy, $entities, {
      RW_TAXONOMY_ROLE_LHS=>$RW_TAXONOMY_ROLE_LHS,
      RW_TAXONOMY_ORGANIZATION_LHS=>$RW_TAXONOMY_ORGANIZATION_LHS,
      RW_TAXONOMY_GEOGRAPHY_LHS=>$RW_TAXONOMY_GEOGRAPHY_LHS,
      }),

    # possíveis cargos de pessoas, obtidos a partir da taxonomia, na chave pessoa
    RW_TAXONOMY_ROLE_LHS => $RW_TAXONOMY_ROLE_LHS,
    RW_TAXONOMY_ORGANIZATION_LHS => $RW_TAXONOMY_ORGANIZATION_LHS,
    RW_TAXONOMY_GEOGRAPHY_LHS => $RW_TAXONOMY_GEOGRAPHY_LHS,
    RW_TAXONOMY_OTHER => $RW_TAXONOMY_OTHER,
    }, $class;

  return $self;
}

# opens a file and reads lines from it
sub recognize_file{
  my ($self, $fn) = @_;

  open(my $fh, "<", $fn) or die "cannot open '$fn': $!";
  $self->recognize_file_handle($fh);
  close($fh);

  return 1;
}

# reads lines from a provided file handle
sub recognize_file_handle{
  my ($self, $fh) = @_;
  while(my $line = <$fh>){
    $self->recognize_line($line);
  }
  return 1;
}

# reads lines from a string
sub recognize_string{
  my ($self, $str) = @_;
  for my $line (split /^/, $str){
    $self->recognize_line($line);
  }
  return 1;
}

# extracts entities from a line
sub recognize_line{
  my $self = shift;
  my $line = normalize_line(shift);

  eval $self->{rewrite_rules};
  TRACE($@) if ($@);

  do{
    $self->{NUMBER_OF_RECOGNITIONS} = 0;
    $line = rewrite_entities($line);
    TRACE("\nREWROTE " . $self->{NUMBER_OF_RECOGNITIONS} . " TIMES\n");
    TRACE("\n\nLINE: $line\n\n");
  }while($self->{NUMBER_OF_RECOGNITIONS} > 0);

  do{
    $self->{NUMBER_OF_RECOGNITIONS} = 0;
    $line = other_stuff_from_taxonomy($line);
  }while($self->{NUMBER_OF_RECOGNITIONS} > 0);

  (my $l = $line) =~ s/[^\w\:\{\}]+/ /g;
  TRACE("\n\nSTRIPPED_LINE: $l\n\n");
  find_relations($l);

  $self->review_entities();
  return 1;
}

sub add_entity {
  my ($self, $entity) = @_;

  my $ent;
  foreach my $key (keys %$entity) {
    if( defined($self->{entities}{$key}) ){
      $ent = $self->{entities}{$key};
    }else{
      $ent = $self->{entities}{$key} = {};
    }

    foreach my $subkey (keys %{$entity->{$key}}) {
      my $arr;

      if( defined $ent->{$subkey} ){
        $arr = $ent->{$subkey};
      }else{
        $arr = $ent->{$subkey} = [];
      }

      foreach my $elem (@{$entity->{$key}{$subkey}}) {
        next if( grep { $_ eq $elem } @$arr );
        push @$arr, $elem;
      }
    }
  }
}

# tidy up after recognizing a line
sub review_entities{
  my ($self) = @_;
  my $ents = $self->{entities};

  # merge de coisas que aparecem em minuscula e maiuscula
  # exemplo: meter o que está em 'câmara' em 'Câmara' e remover 'câmara'
  foreach my $k (keys %$ents) {
    if( $k =~ m/^\p{Ll}/ && defined $ents->{ucfirst $k} ){
      $self->add_entity({
        ucfirst($k) => $ents->{$k}
      });
      delete $ents->{$k};
    }
  }

  # pessoas 'João Miguel Rodrigues', 'Miguel Rodrigues' e 'Rodrigues' podem ser a mesma
  # como também podem não ser a mesma pessoa, não juntar informações
  {
    my @pessoas;
    foreach my $k (keys %$ents) {
      if( defined $ents->{$k}{tipo} && grep {$_ eq 'person'} @{$ents->{$k}{tipo}} ){
        push @pessoas, $k;
      }
    }

    foreach my $p (@pessoas) {
      # quando $p é a parte final de outro nome
      if( my @casos = grep {$_ =~ m/$p$/ && $_ ne $p} @pessoas ){
        foreach my $caso (@casos) {
          $self->add_entity({
            $caso => {'alias' => [$p]},
            $p => {'alias' => [$caso]},
          });
        }
      }
      # quando $p começa e acaba com as mesmas palavras que um outro nome
      if( $p =~ m/\s\p{L}+\s/ ){
        my ($inicio,$fim) = $p =~ m/^(\p{L}+)(?:\s\p{L}+)*\s(\p{L}+)$/;
        if( my @casos = grep {$_ =~ m/^$inicio\s(\p{L}+\s)*$fim$/ && $_ ne $p} @pessoas ){
          foreach my $caso (@casos) {
            $self->add_entity({
              $caso => {'alias' => [$p]},
              $p => {'alias' => [$caso]},
            });
          }
        }
      }
    }
  };
}

# returns entities
sub entities{
  my $self = shift;
  return $self->{entities};
}

####################################
# Class methods

# removes unuseful parts of a line
sub normalize_line {
  my $line = shift;

  $line =~ s/\{\}//g;
  $line =~ s/[\_]+/ /g;
  $line =~ s/\s+/ /g;
  #join ' ', (split(/[^\w0-9()]+/, shift));

  return $line;
}

sub get_words_from_tree {
  my ($tree) = @_;

  my @words = ();

  return @words unless( ref($tree) eq 'HASH' );

  push @words, keys %$tree;
  foreach my $key (keys %$tree) {
    push @words, get_words_from_tree($tree->{$key});
  }

  return @words;
}

sub taxonomy_to_regex {
  my $taxonomy = shift;
  my $key;
  my @words;

  while ($key = shift) {
    push @words, get_words_from_tree($taxonomy->{$key});
  }

  my @taxonomy_rules;
  # o sort é para as palavras mais compridas estarem primeiro e assim
  #  fazerem match antes de se experimentar as mais curtas
  foreach my $word (sort { length $b <=> length $a } @words) {
    $word = lc $word;
    # meter uma versão com a primeira letra maiuscula e a primeira
    #      letra de cada palavra com 4 ou mais letras em maiúscula
    $word =~ s/(?<!\p{L})(\p{L})(?=\p{L}\p{L}\p{L}+)/'['.uc($1).lc($1).']'/ge;
    $word =~ s/^(\p{L})/'['.uc($1).lc($1).']'/ge;
    push @taxonomy_rules, $word;
  }

  if( @taxonomy_rules ){
    return join '|', @taxonomy_rules;
  }else{
    return '^(?=y)w'; # falha sempre quase imediatamente
  }
}

1;
__END__

=encoding utf8

=head1 NOME

NER - Name Entity Recognition, reconhecedor de nomes e entidades para textos em Portguês




=head1 SINOPSE

  use NER;
  my $recognizer = NER->new($names,$taxonomy);

  # read text from a string
  $recognizer->recognize_string(STDIN);

  #OR
  # read text from file
  $recognizer->recognize_file($some_text_file);

  #OR
  # read text from STDIN
  $recognizer->recognize_file_handle(STDIN);

  my $entities = $recognizer->entities;




=head1 DESCRIÇÃO

O Name Entity Recognition permite reconhecer entidades presentes em textos escritos em linguagem natural sem anotações. Para auxiliar esse reconhecimento, pode ser fornecida uma lista de nomes/apelidos e uma taxonomia (organizada em árvore). Além destes, o módulo usa também um dicionário jspell da língua portuguesa.

Ao reconhecer um texto, o NER encontra palavras e expressões com grande probabilidade de serem entidades e submete-as a um sub-módulo (NER::Recognizer) que as tenta identificar como algum tipo de entidade (pessoa, localização, etc). As entidades reconhecidas são guardadas e o texto original é anotado. Por fim as entidades reconhecidas e o texto anotado são revistos à procura de possíveis relações entre as entidades.

O NER está dividido em vários módulos:

=over

=item * B<NER>

Módulo base, itera sobre o texto, submetendo várias possíveis entidades para serem identificadas pelo NER::Recognizer.

=item * B<NER::Recognizer>

Sub-módulo que gere a identificação de entidades no texto.

=item * B<NER::Logger>

Sub-módulo para facilitar a activação/desactivação de texto de debug.

=item * B<NER::Recognizers::*> (excepto NER::Recognizers::Base)

Sub-módulos que indicam a probabilidade de uma possível entidade ser de um tipo específico (uma pessoa ou localização, por exemplo).

Todos estes módulos são do tipo NER::Recognizers::Base (usando @ISA).

=item * B<NER::Recognizers::Base>

Sub-módulo que não é usado directamente para reconhecer texto, mas tem métodos comuns a todos os outros reconhecedores.

=back

=head2 ESTRUTURAS DE DADOS

=head3 ESTRUTURA EM ÁRVORE

Sempre que forem referidas estruturas em árvore, são estruturas recursivas formadas por várias hashes, em que cada nó é uma hash identificada por uma chave da hash do nó imediatamente acima e cada folha é um valor identificado por uma chave da hash do nó que a suporta.

Demonstração:

  {
    'um' => 1,
    'três' => {
      'quatro' => 'abc',
      'cinco' => {
        'seis' => 6,
        'sete' => 7
      }
    }
    'dois' => undef
  }

Corresponde à árvore:

      < raiz >
     /   |    \
    /    |     \
  um   dois    três
   |     |     |   \
   1  undef  cinco quatro
            /   \      \
          seis  sete   abc
           |      |
           6      7

=head3 ESTRUTURA DE NOMES

Lista de nomes como chaves de uma hash. O reconhecedor funciona com uma hash vazia, mas terá piores resultados.

A lista é uma hash com o seguinte formato:

  {
    "António"=>"nome",
    "Augusto"=>"misto"
    "José"=>"nome",
    "Martinho"=>"misto",
    "Silva"=>"apelido"
  }

Em que "nome", "apelido" e "misto" significam que a palavra é usada como primeiro nome, como apelido ou ambos, respectivamente.

=head3 ESTRUTURA DA TAXONOMIA

Uma Árvore de profundidade variável na qual as folhas são ignoradas. Apenas as chaves das hashes são usadas como entidades no reconhecimento de texto.

Existem algumas chaves especiais cujas chaves (das hashes) na árvore descendente são associadas a determinados tipos de entidade:

=over

=item * B<'pessoa'> contém elementos textuais do tipo 'C<role>', que representam profissões ou cargos que uma pessoa possa ter;

=item * B<'organização'> contém elementos textuais do tipo 'C<organization>', que representam instituições, organizações e outras entidades colectivas;

=item * B<'geografia'> contém elementos textuais do tipo 'C<geography>', que representam entidades identificativas de elementos geográficos (exemplo: rio, vale, montanha);

=item * B<'...'> todos os outros elementos textuais na taxonomia são de tipo desconhecido e ficam associados ao tipo 'C<other>'. Pode.

=back

Um exemplo real (resumido):

  {
    'pessoa' => {
      'advogado' => 1,
      'arquitecto' => 1,
      'atleta' => {
        'futebolista' => 1
      },
      'escritor' => {
        'poeta' => 1
      }
    },

    'organização' => {
      'organização_histórica' => {
        'dinastia' => 1,
        'cortes' => 1
      },
      'comissão' => {
        'comissão europeia' => 1
      }
    },

    'outro' => {
      'signo' => 1,
      'regulamento geral de taxas' => 1
    },

    'ainda mais um' => {
      'mosca' => 1
    }
  }

De forma detalhada, tem-se que os elementos 'advogado', 'arquitecto', 'atleta', 'futebolista', 'escritor' e 'poeta' são do tipo 'C<role>'.

Os elementos 'dinastia', 'cortes', 'comissão' e 'comissão europeia' são do tipo 'C<organization>'. Note-se que 'organização_histórica' é um elemento, mas nunca será reconhecido porque todos os '_' são removidos aquando da normalização do texto.

Os elementos 'signo', 'mosca' e 'regulamento geral de taxas' são do tipo 'C<other>'. Como demonstrado, os elementos do tipo 'C<other>' não precisam de estar todos aninhados na hash correspondente a uma chave principal da Árvore (no exemplo estão nas chaves 'outro' e 'ainda mais um').

As chaves principais da Árvore (no exemplo são 'pessoa', 'organização', 'outro' e 'ainda mais um') não são considerados elementos a reconhecer. Caso se queira reconhecer o texto 'pessoa' como uma entidade é preciso que esta seja adicionada aninhada na hash correspondente a uma chave principal da Árvore.

Na maior parte dos casos, não há necessidade de incluir expressões duplicadas na taxonomia que apenas difiram em termos de maiúsculas e minúsculas. Ao ler os valores da taxonomia, estes são alterados de forma a que, por exemplo, o elemento 'regulamento geral de taxas' permita capturar a entidade 'Regulamento Geral de Taxas' e 'regulamento Geral de Taxas', mas não 'regulamento geral De taxas'. Para mais especificidade, consultar a descrição da subrotina L<taxonomy_to_regex|/"taxonomy_to_regex">.

=head3 ESTRUTURA DE ENTIDADES RECONHECIDAS

Esta estrutura vai sendo construída à medida que vão sendo lidas linhas/textos e pode ser obtida usando a subrotina L<entities|/"entities">.

Segue o seguinte formato:

  {
    'entidade' => {
      'relação' => [
        'valor',
        'valor',
        (...)
      ],
      'outra_relação' => [
        'valor',
        'valor',
        (...)
      ]
    },
    'outra_entidade' => {
      (...)
    },
    (...)
  }

E um exemplo de valoração:

  {
    'António Costa' => {
      'tipo' => ['person'],
      'alias' => ['Costa'],
    },
    'Costa' => {
      'tipo' => ['person'],
      'alias' => ['António Costa'],
    },
    'Worten' => {
      'tipo' => ['organization']
    },
    'Signo' => {
      'tipo' => ['other']
    }
  }


=head1 SUBROTINAS

=head2 EXPORT

None by default.

=head2 EXPORT_OK

=head3 normalize_line

Recebe um argumento: uma linha. Remove chavetas e agrupa todos os conjuntos de um ou mais caracteres de whitespace num único espaço.

Esta subrotina é usada para normalizar cada linha antes de ser interpretada.

=head3 get_words_from_tree

Obtém todas as chaves existentes numa estrutura lógica de árvore composta por várias hashes.

Exemplo: Dada a árvore

  {
    'um' => 'esta string não',
    'três' => {
      'quatro' => 4,
      'cinco' => ['estas', 'strings', 'também', 'não']
    }
    'dois' => undef
  }

A subrotina retorna

  qw(um dois três quatro cinco)

=head3 taxonomy_to_regex

Recebe uma taxonomia e uma ou mais chaves. Dá como resultado uma expresão regular que pode ser utilizada para capturar qualquer um dos elementos na taxonomia (sem contar com as chaves passadas como argumento).

A expressão regular gerada tem algumas características fundamentais para ter maior utilidade:

=over

=item * É uma expressão regular com várias alternativas, como C</gigante|gelado|pneu|sol/>

=item * As várias alternativas estão ordenadas por ordem decrescente de comprimento:

Tendo a expressão C</filho|filhote/>, nunca é capturada a string C<filhote> porque antes disso já apanhou C<filho>.

Ordenando por ordem decrescente de comprimento da string (C</filhote|filho/>) a string C<filho> só é capturada em casos em que não foi capturada a string C<filhote>.

Por esta razão as várias alternativas são ordenadas antes de serem introduzidas na expressão regular.

=item * As várias alternativas capturam texto em I<lower case>, em I<Title Case> e numa mistura dos dois:

Um elemento como C<'presidente'> dá origem à expresão regular C</[Pp]residente/>.

Um elemento como C<'regulamento geral de taxas'> dá origem à expressão regular C</[Rr]egulamento [Gg]eral de [Tt]axas/>, capturando strings como C<'Regulamento Geral de Taxas'> ou C<'regulamento Geral de Taxas'>.

Especificamente, a primeira letra da string e a primeira letra de todas as palavras com 4 ou mais letras é transformada numa classe que permite a versão maiúscula e minúscula da letra.

=back

=head2 INSTANCE SUBROUTINES

=head3 new

Cria uma nova instância de NER, com todos os elementos necessários ao reconhecimento de texto.

B<Argumentos:>

=over 2

=item 1. Uma L<estrutura de nomes|/"ESTRUTURA DE NOMES">

=item 2. Uma L<estrutura da taxonomia|/"ESTRUTURA DA TAXONOMIA">

=item 3. (opcional) Diferentes regras de re-escrita que substituiem as predefinidas

Estas regras de re-escrita devem já ter sido processadas pelo módulo I<Text::RewriteRules> e devem estar em formato de string preparada para ser submetida a um I<eval>.

Todas as regras definidas no REWRITE_RULES_BLOCK deste módulo têm de estar definidas neste argumento.

=back

Neste método são criadas as expressões regulares a partir da taxonomia (usando L<taxonomy_to_regex|/"taxonomy_to_regex">) que são usadas no RewriteRules e nos Recognizers. São criadas as expressões regulares para os tipos C<'role'>, C<'organization'>, C<'geography'> e C<'other'>.

É também inicializado um dicionário Jspell de Português e um novo objecto do tipo C<Recognizer>.


=head3 recognize_file

Recebe como argumento o caminho para um ficheiro.

Inicia o reconhecimento de um ficheiro. Começa por abrir o ficheiro e depois delega o reconhecimento para L<recognize_file_handle|/"recognize_file_handle">.

=head3 recognize_file_handle

Recebe como argumento um C<FILE_HANDLE> de onde serão lidas as linhas a reconhecer.

Esta subrotina só percorre todas as linhas, delegando o reconhecimento das entidades na linha para L<recognize_line|/"recognize_line">.

=head3 recognize_string

Recebe como argumento uma C<string> de onde serão lidas as linhas a reconhecer.

Esta subrotina só percorre todas as linhas, delegando o reconhecimento das entidades na linha para L<recognize_line|/"recognize_line">.

=head3 recognize_line

Recebe a linha na qual devem ser reconhecidas entidades, L<normaliza-a|/"normalize_line"> e depois faz eval às RewriteRules (que originais quer redefinidas).

Depois a linha é submetida a um L<processo de reconhecimento de entidades|/"rewrite_entities"> (excepto entidades do tipo C<'other'>) e é re-submetida a este processo até não serem encontradas mais entidades.

Depois deste reconhecimento primário, a linha é submetida a um L<processo de reconhecimento de entidades|/"other_stuff_from_taxonomy"> do tipo C<'other'> e é re-submetida a este processo até não serem encontradas mais entidades desse tipo.

Antes de finalizar o reconhecimento das entidades da linha, é feita uma tentativa de encontrar relacionamentos entre as entidades, usando L<find_relations|/"find_relations"> numa versão da linha com anotações e sem sinais de pontuação.

Por fim é invocado o L<review_entities|/"review_entities"> para fazer um tratamento final aos elementos recolhidos.

=head3 add_entity

TODO (já adicionei informação sobre a estrutura, deve ser pouco mais que meter o link)

=head3 review_entities

TODO

=head3 entities

TODO

=head2 REWRITERULES SUBROUTINES

Todos os métodos do rewrite rules, cenas de eval e tal TODO



=head1 Random stuff

* um objecto NER permite reconhecer vários textos e no final dá todas as entidades encontradas em todos os textos (por causa da forma como algumas entidades são reconhecidas, isto pode significar resultados diferentes conforme a ordem de reconhecimento dos textos).

* como gerar esta documentação e como correr a aplicação

* dependências

* TODO

* tudo o que está aqui em baixo

                 |
                \ /
                 V

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>chalkos@nonetE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

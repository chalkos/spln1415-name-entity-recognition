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

require Exporter;

our @ISA = qw(Exporter);
our @EXPORT_OK = qw( Normalize_line search_tree get_words_from_tree);

our $VERSION = '0.01';

####################################
# Rewrite rules (uses heredoc so syntax
# highlight continues to work for 'normal' perl code)
my $rewrite_rules = << 'REWRITE_RULES_BLOCK';
{no warnings 'redefine';

my $RW_TAXONOMY_ROLE_LHS = $self->{RW_TAXONOMY_ROLE_LHS};
my $RW_TAXONOMY_ORGANIZATION_LHS = $self->{RW_TAXONOMY_ORGANIZATION_LHS};

my $taxoBegin = '(o|a|ao|à|aos|ás)';
my $taxoLink  = 'da|de|do|das|dos|Da|De|Do|Das|Dos';

my $word = '\p{L}+';

################################################
################################################
RULES rewrite_taxonomy
(?:[^\p{L}]|^)(\p{L}\p{Ll}+)=e=>"{taxo:$1}"!! $self->is_interesting($1)
(?:[^\p{L}]|^){taxo:(.*?)}\s(\p{L}\p{Ll}+)=e=>"{taxo:$1 $2}"!! $self->is_interesting($1,$2)
(?:[^\p{L}]|^)(\p{L}\p{Ll}+)\s{taxo:(.*?)}=e=>"{taxo:$1 $2}"!! $self->is_interesting($1,$2)
(?:[^\p{L}]|^){taxo:(.*?)}\s($taxoLink)\s(\p{L}\p{Ll}+)=e=>"{taxo:$1 $2 $3}"!! $self->is_interesting($1,$2,$3)
(?:[^\p{L}]|^)(\p{L}\p{Ll}+)\s($taxoLink)\s{taxo:(.*?)}=e=>"{taxo:$1 $2 $3}"!! $self->is_interesting($1,$2,$3)
ENDRULES

#((?<!\p{L})$word\s$word\s$word\s$word\s$word(?!\p{L}))=e=>$RWTEXT!! $self->recognize($1)
#((?<!\p{L})$word\s$word\s$word\s$word(?!\p{L}))=e=>$RWTEXT!! $self->recognize($1)
#((?<!\p{L})$word\s$word\s$word(?!\p{L}))=e=>$RWTEXT!! $self->recognize($1)
#((?<!\p{L})$word\s$word(?!\p{L}))=e=>$RWTEXT!! $self->recognize($1)
#((?<!\p{L})$word(?!\p{L}))=e=>$RWTEXT!! $self->recognize($1)

# RewriteRules bug: ^ não funciona para delimitar inicio de string quando se usa /m. falha sempre
# RewriteRules bug: lookbehinds positivos nao funcionam no inicio da expressão regular (com /m)
RULES/m rewrite_entities
({.*?:.*?})=e=>$1

([Cc][aâ]mara\s[Mm]unicipal)=e=>$RWTEXT!! $self->recognize($1)
([Cc][aâ]mara(?!\s[Ff]otogr))=e=>$RWTEXT!! $self->recognize($1)

(?<!\p{L})($RW_TAXONOMY_ROLE_LHS)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
^($RW_TAXONOMY_ROLE_LHS)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
(?<!\p{L})($RW_TAXONOMY_ROLE_LHS)$=e=>$RWTEXT!! $self->recognize($1)

(?<!\p{L})($RW_TAXONOMY_ORGANIZATION_LHS)(?!\p{L})=e=>$RWTEXT!! $self->recognize2($1)
^($RW_TAXONOMY_ORGANIZATION_LHS)(?!\p{L})=e=>$RWTEXT!! $self->recognize2($1)
(?<!\p{L})($RW_TAXONOMY_ORGANIZATION_LHS)$=e=>$RWTEXT!! $self->recognize2($1)

(?<!\p{L})($NER::Recognizers::Date::REGEX_DATE)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
^($NER::Recognizers::Date::REGEX_DATE)(?!\p{L})=e=>$RWTEXT!! $self->recognize($1)
(?<!\p{L})($NER::Recognizers::Date::REGEX_DATE)$=e=>$RWTEXT!! $self->recognize($1)
(?<!\p{L})((?:no|em) \p{L}+ de|em|ano de) ($NER::Recognizers::Date::REGEX_YEAR)(?!\p{L})=e=>$1.' '.$RWTEXT!! $self->recognize($2)
(?<!\p{L})((?:no|em) \p{L}+ de|em|ano de) ($NER::Recognizers::Date::REGEX_YEAR)$=e=>$1.' '.$RWTEXT!! $self->recognize($2)

(\p{Lu}\p{Ll}+((\s(da|de|do|das|dos|Da|De|Do|Das|Dos)\s|\s)\p{Lu}\p{Ll}+)*)=e=>$RWTEXT!! $self->recognize($1)

(\p{Lu}\p{Ll}+(\s\p{Lu}\p{Ll}+)*)=e=>'{entity:'.$1.'}'!! $self->is_an_entity($1)
ENDRULES

RULES loose_ends
ENDRULES
################################################
################################################
}
REWRITE_RULES_BLOCK

# variável global com o texto de substituição no right hand side da regra
our $RWTEXT;


#TODO: estava a fazer isto para obter uma lista de palavras a partir da taxonomia
#      para depois meter uma regra para cada no sitio onde diz
#      no texto do rewriterules: ~~~taxonomy_rules~~~
#      - além disso tenho que fazer um recognizer para funções de pessoas/trabalhos que depois
#        apanhe as capturas do rewrite
#      - depois tentar apanhar o lisboa em presidente da Câmara de Lisboa António Costa


####################################
# Methods used by rewrite rules

sub is_interesting{
  my $self = shift;
  my $str = join ' ', @_;

  #debug("::::::::::::::::::::$str");

  if( my $path = search_tree($self->{taxonomy}, $str) ){
    #debug(" <------------- $path");
  }

  #debug("\n");

  return 0;
}

sub recognize2{
  print "~~~~organization: " . $_[1] . "\n";
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
    $str => { is_a => $tipo },
  });

  # definir o texto de substituição
  $RWTEXT = '{'.$tipo.':'.$str.'}';

  # incrementar o contador de reescritas com sucesso
  $self->{NUMBER_OF_RECOGNITIONS}++;

  return 1;
}

sub is_an_entity{
  return 0;
  my ($self, $str) = @_;

  #debug("\n=====start IS_AN_ENTITY=====\n");

  my $nomes_sim    = 0;
  my $nomes_talvez = 0;
  my $nomes_nao    = 0;

  foreach my $n (split /\s/,$str) {
    debug("   palavra: $n -> ");

    # ver na análise morfológica
    my @fea = $self->{dict}->fea($n);

    my $palavras_invalidas = 0;
    my $palavras_validas = 0;
    foreach my $analise ( @fea ) {
      if($analise->{CAT} =~ /nc|np/){
        $palavras_validas++;
      }else{
        $palavras_invalidas++;
      }
    }

    if($palavras_validas > 0){
      $nomes_sim++;
      debug("nome comum (morf)\n");
    }elsif($palavras_invalidas > 0){
      $nomes_nao++;
      debug("não é nome comum (morf)\n");
    }else{
      $nomes_talvez++;
      debug("não sei o que é isto (morf)\n");
    }

    if( $nomes_sim == 0 && $nomes_talvez == 0 && $nomes_nao > 0 ){
      # se a primeira palavra que se detectou não corresponde a um nome, abortar
      debug("=====IS_AN_ENTITY? NO=====\n");
      return 0;
    }
  }

  debug("=====IS_AN_ENTITY? YES=====\n");

  $self->add_entity({
    $str => {
      is_a => 'entity'
      },
    });

  return 1;
}

####################################
# Object methods

sub new{
  my ($class, $names, $taxonomy, $re_write) = @_;

  $re_write = $rewrite_rules if( !defined $re_write || (defined $re_write && !@$re_write) );
  #print STDERR Dumper($re_write);

  my $RW_TAXONOMY_ROLE_LHS = taxonomy_to_regex($taxonomy, 'pessoa');
  my $RW_TAXONOMY_ORGANIZATION_LHS = taxonomy_to_regex($taxonomy, 'organização');

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
      }),

    # possíveis cargos de pessoas, obtidos a partir da taxonomia, na chave pessoa
    'RW_TAXONOMY_ROLE_LHS' => $RW_TAXONOMY_ROLE_LHS,
    'RW_TAXONOMY_ORGANIZATION_LHS' => $RW_TAXONOMY_ORGANIZATION_LHS,
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
  my $line = Normalize_line(shift);

  eval $self->{rewrite_rules};
  print STDERR $@ if ($@);

  do{
    $self->{NUMBER_OF_RECOGNITIONS} = 0;
    $line = rewrite_entities($line);
    print STDERR "\nREWROTE " . $self->{NUMBER_OF_RECOGNITIONS} . " TIMES\n";
  }while($self->{NUMBER_OF_RECOGNITIONS} > 0);
  $line = loose_ends($line);

  print STDERR "\n\nLINE: $line\n\n";

  $self->review_entities();
  return 1;
}

sub add_entity {
  my ($self, $entity) = @_;

  foreach my $key (keys %$entity) {
    if( defined($self->{entities}{$key}) ){
      my $existing = $self->{entities}{$key};
      push @$existing, $entity->{$key};
    }else{
      $self->{entities}{$key} = [$entity->{$key}];
    }
  }
}

# tidy up after recognizing a line
sub review_entities{
  my ($self) = @_;

  #TODO
  # ajustar nomes, por exemplo:
  # explicitar que as pessoas 'João Miguel Rodrigues', 'Miguel Rodrigues' e 'Rodrigues'
  # são a mesma pessoa e juntar as informações que possam estar divididas pelas 3 entidades
}

# gets existing entities
# if the entity has an array with only one element, use that element
# otherwise use the array as is.
sub entities{
  my $self = shift;

  my $ent = {};

  foreach my $key (keys %{$self->{entities}}) {
    my $val = $self->{entities}{$key};

    if( @$val == 1 ){
      $ent->{$key} = $val->[0];
    }else{
      $ent->{$key} = $val;
    }
  }

  return $ent;
}

####################################
# Class methods

# removes unuseful parts of a line
sub Normalize_line {
  my $line = shift;

  $line =~ s/\{\}//g;
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
  my ($taxonomy, $key) = @_;

  if( defined $taxonomy->{$key} ){
    my @taxonomy_rules;
    my @words = get_words_from_tree($taxonomy->{$key});
    # o sort é para as palavras mais compridas estarem primeiro e assim
    #  fazerem match antes de se experimentar as mais curtas
    foreach my $word (sort { length $b <=> length $a } @words) {
      $word = lc $word;
      # meter uma versão com a primeira letra maiuscula e a primeira
      #      letra de cada palavra com 4 ou mais letras em maiúscula
      $word =~ s/(?<!\p{L})(\p{L})(?=\p{L}\p{L}\p{L}+)/'['.uc($1).$1.']'/ge;
      $word =~ s/^(\p{L})/'['.uc($1).$1.']'/ge;
      push @taxonomy_rules, $word;
    }
    return join '|', @taxonomy_rules;
  }else{
    return '^(?=y)w'; # falha sempre quase imediatamente
  }
}

sub search_tree {
  my ($tree, $search) = @_;

  return '' unless( ref($tree) eq 'HASH' );

  return $search if( defined($tree->{$search}) && $tree->{$search} == 1 );

  foreach my $key (keys %$tree) {
    my $result = search_tree( $tree->{$key}, $search );
    return "$key, $result" if($result);
  }

  return '';
}

sub debug {
  my $str = shift;
  #print STDERR $str;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

# NOTA:
# No objeto abençoado, todas as chaves que estão em CAPS LOCK são muito
# internas e não faz sentido serem acedidas de fora a nao ser para configuração

=head1 NAME

NER - Perl extension for blah blah blah

=head1 SYNOPSIS

  use NER;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for NER, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



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

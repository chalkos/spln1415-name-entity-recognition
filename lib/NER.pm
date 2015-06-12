package NER;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Lingua::Jspell;
use Text::RewriteRules;

use NER::Recognizer;

use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( Normalize_line search_tree );

our $VERSION = '0.01';

####################################
# Rewrite rules (uses heredoc so syntax
# highlight continues to work for 'normal' perl code)
my $rewrite_rules = << 'REWRITE_RULES_BLOCK';
{no warnings 'redefine';

# começa numa cena da taxonomia, depois tem nomes comuns e cenas em maiusculas e (de|do|da, etc)
my $taxoBegin = '(o|a|ao|à|aos|ás)';
my $taxoLink  = 'da|de|do|das|dos|Da|De|Do|Das|Dos';

################################################
################################################
RULES rewrite_taxonomy
(?:[^\p{L}]|^)(\p{L}\p{Ll}+)=e=>"{taxo:$1}"!! $self->is_interesting($1)
(?:[^\p{L}]|^){taxo:(.*?)}\s(\p{L}\p{Ll}+)=e=>"{taxo:$1 $2}"!! $self->is_interesting($1,$2)
(?:[^\p{L}]|^)(\p{L}\p{Ll}+)\s{taxo:(.*?)}=e=>"{taxo:$1 $2}"!! $self->is_interesting($1,$2)
(?:[^\p{L}]|^){taxo:(.*?)}\s($taxoLink)\s(\p{L}\p{Ll}+)=e=>"{taxo:$1 $2 $3}"!! $self->is_interesting($1,$2,$3)
(?:[^\p{L}]|^)(\p{L}\p{Ll}+)\s($taxoLink)\s{taxo:(.*?)}=e=>"{taxo:$1 $2 $3}"!! $self->is_interesting($1,$2,$3)
ENDRULES

# RewriteRules bug: ^ não funciona para delimitar inicio de string quando se usa /m. falha sempre
RULES/m rewrite_entities
({.*?:.*?})=e=>$1
(\p{Lu}\p{Ll}+((\s(da|de|do|das|dos|Da|De|Do|Das|Dos)\s|\s)\p{Lu}\p{Ll}+)*)=e=>'{person:'.$1.'}'!! $self->is_a_person($1)
(\p{Lu}\p{Ll}+((\s(da|de|do|das|dos|Da|De|Do|Das|Dos)\s|\s)\p{Lu}\p{Ll}+)*)=e=>'{location:'.$1.'}'!! $self->is_a_location($1)
(\p{Lu}\p{Ll}+(\s\p{Lu}\p{Ll}+)*)=e=>'{entity:'.$1.'}'!! $self->is_an_entity($1)
ENDRULES

RULES loose_ends
ENDRULES
################################################
################################################
}
REWRITE_RULES_BLOCK

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

sub is_a_location{
  my ($self, $str) = @_;

  my $str_original = $str;

  # remover partes dispensáveis
  $str =~ s/\s(da|de|do|das|dos|Da|De|Do|Das|Dos)\s/ /g;

  #debug("\n=====start IS_A_LOCATION=====\n");

  my $location_sim    = 0;
  my $location_talvez = 0;
  my $location_nao    = 0;

  foreach my $n (split /\s/,$str) {
    debug("   palavra: $n -> ");

    # ver na análise morfológica
    my @fea = $self->{dict}->fea($n);

    my $palavras_invalidas = 0;
    my $palavras_validas = 0;
    foreach my $analise ( @fea ) {
      if($analise->{CAT} =~ /np/ && $analise->{SEM} =~ /cid|ter/){
        $palavras_validas++;
      }else{
        $palavras_invalidas++;
      }
    }

    if($palavras_validas > 0){
      $location_sim++;
      debug("localidade (morf)\n");
    }elsif($palavras_invalidas > 0){
      $location_nao++;
      debug("não é localidade (morf)\n");
    }else{
      $location_talvez++;
      debug("não sei o que é isto (morf)\n");
    }

    if( $location_sim == 0 && $location_talvez == 0 && $location_nao > 0 ){
      # se a primeira palavra que se detectou não corresponde a um nome, abortar
      #debug("\n=====IS_A_LOCATION? NO=====\n");
      return 0;
    }
  }

  debug("=====IS_A_LOCATION? YES=====\n");

  $self->add_entity({
    $str_original => {
      is_a => 'location'
      },
    });

  return 1;
}

sub is_an_entity{
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

sub is_a_person{
  my ($self, $str) = @_;

  my $str_original = $str;

  # remover partes dispensáveis
  $str =~ s/(da|de|do|das|dos|Da|De|Do|Das|Dos)\s//g;

  my $nomes_sim    = 0;
  my $nomes_talvez = 0;
  my $nomes_nao    = 0;

  debug("\n=====start IS_A_PERSON=====\n");

  my @palavras = split /\s/,$str;

  foreach my $n (@palavras) {
    debug("   palavra: $n -> ");

    # ver na hash dos nomes
    my $nome_encontrado_na_hash = 0;
    if( defined( my $tipo = $self->{names}->{$n} ) ){
      debug("hash de nomes: $tipo; ");
      $nome_encontrado_na_hash=1;
    }

    # ver na análise morfológica
    my @fea = $self->{dict}->fea($n);

    # se a palavra tiver uma possivel interpretação de nome próprio:
    # --se a semantica da palavra for nome português ou estrangeiro
    # ----provavelmente é nome de pessoa, continuar a ver o resto das análises morfológicas
    # --senão e se o nome a analisar tiver apenas uma palavra (possivelmente uma referência a uma pessoa usando apenas o apelido)
    # ----verificar se esse possível apelido já faz parte de algum nome de pessoa
    # ----se sim
    # ------provavelmente é uma pessoa, continuar a ver o resto das análises morfológicas
    # ----se não
    # ------provavelmente não é pessoa (e é uma terra ou cidade), continuar a ver o resto das análises morfológicas
    # --senão
    # ----casos estranhos, marcar como não identificável e continuar a ver o resto das análises morfológicas
    # senão
    # --provavelmente não é pessoa, continuar a ver o resto das análises morfológicas
    my $palavras_invalidas = 0;
    my $palavras_validas = 0;
    foreach my $analise ( @fea ) {
      if($analise->{CAT} =~ /np/){
        if( defined($analise->{SEM}) && $analise->{SEM} =~ /^(p|p1)$/ ){
          $palavras_validas++;
        #}elsif( !(defined($analise->{SEM}) && $analise->{SEM} =~ /cid|ter|country/) ){
        #  $palavras_validas++;
        }elsif(scalar(@palavras) == 1){
          my $pertence = 0;
          foreach my $key (keys %{$self->{entities}}) {
            if($key =~ /(\s|^)$n(\s|$)/ && $self->{entities}{$key}[0]{is_a} eq 'person'){
              $pertence=$key;
              last;
            }
          }
          if($pertence){
            debug("é localidade, mas faz parte do nome '$pertence'; ");
            $palavras_validas++;
          }else{
            debug("localidade que não aparece em nenhum nome até agora; ");
            $palavras_invalidas++;
          }
        }
      }else{
        $palavras_invalidas++;
      }
    }

    # se não houve resultados conclusivos até agora, procurar a palavra nos nomes de pessoa existentes
    if($palavras_invalidas == 0 && $palavras_validas == 0 && scalar(@palavras) == 1){
      foreach my $key (keys %{$self->{entities}}) {
        if($key =~ /(\s|^)$n(\s|$)/ && $self->{entities}{$key}[0]{is_a} eq 'person'){
          debug("não foi identificada, mas faz parte do nome '$key'; ");
          $palavras_validas++;
          last;
        }
      }
    }

    # decidir se a palavra é parte de um nome ou não
    # se houver sinal de que é válida
    # --assinalar que é nome
    # senão e se houver sinal que é inválida
    # --assinalar que não é nome
    # senão (ou seja, não foi possivel identificar) mas foi encontrada na hash de nomes
    # --assinalar que é nome
    # senão (é mesmo não indentificado)
    # --assinalar que poderá ser um nome
    if($palavras_validas > 0){
      $nomes_sim++;
      debug("nome próprio (morf)\n");
    }elsif($palavras_invalidas > 0){
      $nomes_nao++;
      debug("não é nome proprio (morf)\n");
    }elsif($nome_encontrado_na_hash){
      $nomes_sim++;
      debug("é nome próprio (hash de nomes)\n");
    }else{
      $nomes_talvez++;
      debug("não sei o que é isto (morf)\n");
    }

    # se a primeira palavra que se detectou não corresponde a um nome, cancelar. Não é um nome.
    if( $nomes_sim == 0 && $nomes_talvez == 0 && $nomes_nao > 0 ){
      #debug("=====IS_A_PERSON? NO=====\n");
      return 0;
    }
  }
  debug("=====IS_A_PERSON? YES=====\n");

  #TODO: alguma heuristica que use a quantidade de nomes_sim, nomes_talvez e nomes_nao
  #      para ajudar a deterinar se é mesmo um nome de pessoa ou não.

  $self->add_entity({
    $str_original => {
      is_a => 'person'
      },
    });

  return 1;
}

sub post_person {
  my ($self, $fst, $snd) = @_;
  0
}

####################################
# Object methods

sub new{
  my ($class, $names, $taxonomy, $re_write) = @_;
  my $self = bless {
    'dict' => Lingua::Jspell->new("port"),
    'names' => $names,
    'taxonomy' => $taxonomy,
    'entities' => {}, #recognized entities
    'rewrite_rules' => ($re_write ? $re_write : $rewrite_rules),
    }, $class;

  my $rec = NER::Recognizer->new($names, $taxonomy);
  my @result = $rec->recognize('text');
  print Dumper(\@result);

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

  debug("\n\nLINE====>$line<====\n\n");
  $line = rewrite_taxonomy($line);
  $line = rewrite_entities($line);
  $line = loose_ends($line);

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
  print STDERR $str;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

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

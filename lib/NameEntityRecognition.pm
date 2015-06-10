package NameEntityRecognition;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Lingua::Jspell;
use Text::RewriteRules;

use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( Normalize_line );

our $VERSION = '0.01';

####################################
# Rewrite rules (uses heredoc so syntax
# highlight continues to work for 'normal' perl code)
my $rewrite_rules = << 'REWRITE_RULES_BLOCK';
{no warnings 'redefine';
################################################
################################################
RULES/m people
({.*?:.*?})=e=>$1
(\p{Lu}\p{Ll}*(\s((da|de|do|das|dos|Da|De|Do|Das|Dos)\s)?\p{Lu}\p{Ll}*)*)=e=>'{person:'.$1.'}'!! $self->is_a_person($1)
ENDRULES

RULES post_people
{person:(.*?)}\s(e)\s{person:(.*?)}=e=>"{person:$1$2$3}"!! $self->post_person($1,$3)
ENDRULES
################################################
################################################

RULES/m entity
({.*?:.*?})=e=>$1
(\p{Lu}\p{Ll}(\s\p{Lu}\p{Ll})*)=e=>'{entity:'.$1.'}'!! $self->is_an_entity($1)
ENDRULES
################################################
################################################
}
REWRITE_RULES_BLOCK

####################################
# Methods used by rewrite rules

sub is_an_entity{
  my ($self, $str) = @_;

  debug("\n=====start IS_AN_ENTITY=====\n");

  my $nomes_sim    = 0;
  my $nomes_talvez = 0;
  my $nomes_nao    = 0;

  foreach my $n (split /\s/,$str) {
    debug("palavra: $n -> ");

    # ver na análise morfológica
    my @fea = $self->{dict}->fea($n);

    my $nao_nomes_comuns = 0;
    my $nomes_comuns = 0;
    foreach my $analise ( @fea ) {
      if($analise->{CAT} =~ /nc/){
        $nomes_comuns++;
      }else{
        $nao_nomes_comuns++;
      }
    }

    if($nomes_comuns > 0){
      $nomes_sim++;
      debug("nome comum (morf)\n");
    }elsif($nao_nomes_comuns > 0){
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

  debug("\n=====start IS_AN_ENTITY? YES=====\n")

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
  foreach my $n (split /\s/,$str) {
    debug("palavra: $n -> ");

    # ver na hash dos nomes
    if( defined( my $tipo = ($self->{names}->{$n} || $self->{names}->{lc($n)}) ) ){
      debug("um nome $tipo\n");
      $nomes_sim++;
      next;
    }

    # ver na análise morfológica
    my @fea = $self->{dict}->fea($n);

    my $nao_nomes_proprios = 0;
    my $nomes_proprios = 0;
    foreach my $analise ( @fea ) {
      if($analise->{CAT} =~ /np/){
        $nomes_proprios++;
      }else{
        $nao_nomes_proprios++;
      }
    }

    if($nomes_proprios > 0){
      $nomes_sim++;
      debug("nome próprio (morf)\n");
    }elsif($nao_nomes_proprios > 0){
      $nomes_nao++;
      debug("não é nome proprio (morf)\n");
    }else{
      $nomes_talvez++;
      debug("não sei o que é isto (morf)\n");
    }

    if( $nomes_sim == 0 && $nomes_talvez == 0 && $nomes_nao > 0 ){
      # se a primeira palavra que se detectou não corresponde a um nome, abortar
      debug("=====IS_A_PERSON? NO=====\n");
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

  $line = people($line);

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

sub debug {
  my $str = shift;
  print STDERR $str;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NameEntityRecognition - Perl extension for blah blah blah

=head1 SYNOPSIS

  use NameEntityRecognition;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for NameEntityRecognition, created by h2xs. It looks like the
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

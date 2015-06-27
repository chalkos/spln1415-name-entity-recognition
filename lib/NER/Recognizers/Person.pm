package NER::Recognizers::Person;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;


use List::Util qw(sum min);

require NER::Recognizers::Base;
our @ISA = qw(NER::Recognizers::Base);

######################################

sub runAll {
  my ($self,$str) = @_;

  return (
    $self->palavras_individuais($str),
    $self->fim_de_um_nome_ja_existente($str),
    $self->inicio_de_str_corresponde_a_algo_que_nao_nome($str),
  );
}

sub inicio_de_str_corresponde_a_algo_que_nao_nome {
  my ($self,$str) = @_;
  my @partes = split ' ', $str;

  my $offset = 0;
  my @substrs;

  # evitar entrar em ciclo
  my (undef,undef,undef,$fun) = caller(5);
  return 40 if( $fun =~ m/::inicio_de_str_corresponde_a_algo_que_nao_nome/ );

  while( ($offset = index($str, ' ', $offset)) != -1 ) {
    push @substrs, substr( $str, 0, $offset );
    $offset++;
  }

  foreach my $substr (@substrs) {
    print STDERR "checking \"$substr\"...\n";
    my ($type,$lvl,$diff) = $self->re_recognize($substr);
    if( $lvl >= 40 && $type ne 'person' ){
      print STDERR "$substr is not a person!\n";
      return 100-2*$lvl;
    }
  }
  print STDERR "done checking!\n" if( scalar @substrs > 0 );

  return 40;
}




sub fim_de_um_nome_ja_existente{
  my ($self, $str) = @_;

  foreach my $key (keys %{$self->{enti}}) {
    if($key =~ /${str}$/ && $self->{enti}{$key}[0]{is_a} eq 'person'){
      return 90;
    }
  }
  return 40;
}

sub palavras_individuais {
  my ($self, $str) = @_;

  # remover partes dispensáveis
  $str =~ s/\s(da|de|do|das|dos)\s/ /g;

  my @valores;
  foreach my $palavra (split /\s/,$str) {
    my $min = min(
      $self->palavras_individuais_hash_nomes($palavra),
      $self->palavras_individuais_nome_de_pessoa_portugues_ou_estrangeiro($palavra),
      $self->palavras_individuais_localidade($palavra),
    );
    $min = 0 if($min == 999);
    push @valores, $min;
  }

  return sum(@valores) / (scalar @valores);
}

sub palavras_individuais_hash_nomes {
  my ($self, $palavra) = @_;
  return defined($self->{name}->{ucfirst $palavra}) ? 70 : 999;
}

sub palavras_individuais_nome_de_pessoa_portugues_ou_estrangeiro {
  my ($self, $palavra) = @_;

  my @fea = $self->{dict}->fea($palavra);
  foreach my $analise ( @fea ) {
    if( $analise->{CAT} =~ /np/ && defined($analise->{SEM}) && $analise->{SEM} =~ /^(p|p1)$/ ){
      return 70;
    }
  }
  return 999;
}

sub palavras_individuais_localidade {
  my ($self, $palavra) = @_;

  my @fea = $self->{dict}->fea($palavra);
  foreach my $analise ( @fea ) {
    if( $analise->{CAT} =~ /np/ && defined($analise->{SEM}) && $analise->{SEM} =~ /^(cid|ter|country)$/ ){
      return 30;
    }
  }
  return 999;
}

1;

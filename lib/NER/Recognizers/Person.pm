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
  );
}

sub fim_de_um_nome_ja_existente{
  my ($self, $str) = @_;

  foreach my $key (keys %{$self->{enti}}) {
    if($key =~ /${str}$/ && $self->{entities}{$key}[0]{is_a} eq 'person'){
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

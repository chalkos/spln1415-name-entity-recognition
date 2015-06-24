package NER::Recognizers::Location;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

require NER::Recognizers::Base;
our @ISA = qw(NER::Recognizers::Base);

######################################

sub runAll {
  my ($self,$str) = @_;

  return (
    $self->rec_jspell_base($str),
    $self->rec_altas_directas($str),
  );
}

# retira da|de|do|das|dos
# usa o jspell para perceber se as palavras são cidades, terras ou países
# no fim devolve a percentagem (de 0 a 100) de locais em relação ao total de palavras
sub rec_jspell_base {
  my ($self, $str) = @_;

  $str =~ s/\s(da|de|do|das|dos)\s/ /g;

  my ($sim,$nao) = (0,0);

  foreach my $n (split /\s/,$str) {
    my @fea = $self->{dict}->fea($n);
    foreach my $analise ( @fea ) {
      if($analise->{CAT} =~ /np/ && $analise->{SEM} =~ /cid|ter|country/){
        $sim++;
      }else{
        $nao++;
      }
    }
  }

  my $confianca = $sim / ($sim+$nao) * 100;
  #$confianca = 85 if($confianca > 85);

  return $confianca;
}

sub rec_altas_directas {
  my ($self, $str) = @_;

  my @expReg = (
    qr/^vila nova de /,
    qr/^vila /,
  );

  foreach my $exp (@expReg) {
    return 80 if( $str =~ $exp );
  }

  return 0;
}

1;

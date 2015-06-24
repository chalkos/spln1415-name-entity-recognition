package NER::Recognizers::Organization;

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
    $self->rec_especificas($str),
  );
}

sub rec_especificas {
  my ($self, $str) = @_;

  my @expReg = (
    qr/^uni[aã]o europeia$/,
    qr/^c[aâ]mara municipal$/,
    qr/^c[aâ]mara$/,
  );

  foreach my $exp (@expReg) {
    return 100 if( $str =~ $exp );
  }

  return 0;
}

1;

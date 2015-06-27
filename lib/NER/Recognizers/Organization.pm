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
    $self->rec_taxonomia($str),
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

sub rec_taxonomia {
  my ($self, $str) = @_;

  return 0 unless(defined $self->{more}{RW_TAXONOMY_ORGANIZATION_LHS});

  my $regex = $self->{more}{RW_TAXONOMY_ORGANIZATION_LHS};

  return 90 if( $str =~ m/^($regex)$/ );

  return 0;
}

1;

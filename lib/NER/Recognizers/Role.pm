package NER::Recognizers::Role;

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

  return 0 unless(defined $self->{more}{RW_TAXONOMY_LHS});

  my $regex = $self->{more}{RW_TAXONOMY_LHS};

  return 90 if( $str =~ m/^($regex)$/ );

  return 0;
}

1;

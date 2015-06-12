package NER::Recognizers::Person;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
use Lingua::Jspell;

require NER::Recognizers::Base;
our @ISA = qw(NER::Recognizers::Base);

######################################

sub runAll {
  my ($self,$str) = @_;

  return (
    $self->test1($str),
    $self->test2($str),
  );
}

sub test1 {
  my ($self, $str) = @_;
  return 0;
}

sub test2 {
  my ($self, $str) = @_;
  return 0;
}

1;

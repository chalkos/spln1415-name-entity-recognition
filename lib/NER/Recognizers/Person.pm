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
  my ($self,$text) = @_;

  return (
    $self->test1($text),
    $self->test2($text),
  );
}

sub test1 {
  my ($self, $text) = @_;
  return 0;
}

sub test2 {
  my ($self, $text) = @_;
  return 100;
}

1;

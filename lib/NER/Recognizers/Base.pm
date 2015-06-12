package NER::Recognizers::Base;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;

use List::Util qw(sum);
use NER qw(search_tree);

######################################
# todas as subrotinas deste módulo são usadas
# em todos os outros módulos NER::Recognizers::*

sub new{
  my ($class,$names,$taxonomy) = @_;
  my $self = bless {
    'name' => $names,
    'taxo' => $taxonomy,
    }, $class;

  return $self;
}

sub analyse {
  my ($self, $text) = @_;

  my @results = $self->runAll($text);

  return sum(@results) / (scalar @results);
}

1;

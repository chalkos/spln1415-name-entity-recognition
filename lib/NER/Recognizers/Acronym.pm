package NER::Recognizers::Acronym;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Data::Dumper;
$Data::Dumper::Sortkeys = 1;
use Lingua::Jspell;

require NER::Recognizers::Base;
require Exporter;
our @ISA = qw(NER::Recognizers::Base Exporter);
our @EXPORT_OK = qw(REGEX_ACRONYM);

######################################

our $REGEX_ACRONYM = '\p{Lu}{2,}|(?:\p{Lu}\.){2,}';

sub runAll {
  my ($self,$str,$original) = @_;

  return (
    $self->rec_especificas($original),
  );
}

sub rec_especificas {
  my ($self, $str) = @_;

  return 90 if( $str =~ m/^($REGEX_ACRONYM)$/ );

  return 1;
}

1;

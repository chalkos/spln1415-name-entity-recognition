package NER::Recognizers::Date;

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
our @EXPORT_OK = qw(REGEX_DATE REGEX_YEAR);

######################################

our $REGEX_MONTHS_LONG = '([Jj]aneiro|[Ff]evereiro|[Mm]arço|[Aa]bril|[Mm]aio|[Jj]u[nl]ho|[Aa]gosto|[Ss]etembro|[Oo]utubro|[Nn]ovembro|[Dd]ezembro)';
our $REGEX_MONTHS_SHORT = '([Jj]an|[Ff]ev|[Mm]ar|[Aa]br|[Mm]ai|[Jj]u[nl]|[Aa]go|[Ss]et|[Oo]ut|[Nn]ov|[Dd]ez)';
our $REGEX_YEAR = '([0-9]{4}|[0-9]{2})';
our $REGEX_DATE = '('.(join '|',
  # 19 de Setembro de 2003
  # 3 de Out de 98
  '[0-3]?[0-9] de ('.$REGEX_MONTHS_LONG.'|'.$REGEX_MONTHS_SHORT.') de '.$REGEX_YEAR,
  # 19 de Setembro
  # 3 de Out
  '[0-3]?[0-9] de ('.$REGEX_MONTHS_LONG.'|'.$REGEX_MONTHS_SHORT.')',
  # Setembro de 2003
  $REGEX_MONTHS_LONG.' de '.$REGEX_YEAR,
  # (em) 2013
  # (início de) 2010
  #'(?<=(em|de)\s)'.$REGEX_YEAR,
  # 25/12/2013
  # 12-25-2013
  '[0-3]?[0-9][-\/][0-3]?[0-9][-\/]'.$REGEX_YEAR,
  # 2013-12-25
  # 2013/25-12
  $REGEX_YEAR.'[-\/][0-3]?[0-9][-\/][0-3]?[0-9]',
  # Janeiro
  # março
  $REGEX_MONTHS_LONG,
).')';

sub runAll {
  my ($self,$str) = @_;

  return (
    $self->rec_especificas($str),
  );
}

sub rec_especificas {
  my ($self, $str) = @_;

  return 90 if( $str =~ m/$REGEX_DATE/ );
  return 70 if( $str =~ m/$REGEX_YEAR/ );

  return 0;
}

1;

package NameEntityRecognition;

use 5.020001;
use strict;
use warnings;
use utf8::all;

use Lingua::Jspell;

use Data::Dumper;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( Normalize_line );

our $VERSION = '0.01';

####################################
# Object methods

sub new{
  my ($class, $names, $taxonomy) = @_;
  my $self = bless {
    'dict' => Lingua::Jspell->new("port"),
    'names' => $names,
    'taxonomy' => $taxonomy,
    'entities' => {}, #recognized entities
    }, $class;

  return $self;
}

# opens a file and reads lines from it
sub recognize_file{
  my ($self, $fn) = @_;

  open(my $fh, "<", $fn) or die "cannot open '$fn': $!";
  $self->recognize_file_handle($fh);
  close($fh);

  return 1;
}

# reads lines from a provided file handle
sub recognize_file_handle{
  my ($self, $fh) = @_;
  while(my $line = <$fh>){
    $self->recognize_line($line);
  }
  return 1;
}

# reads lines from a string
sub recognize_string{
  my ($self, $str) = @_;
  for my $line (split /^/, $str){
    $self->recognize_line($line);
  }
  return 1;
}

# extracts entities from a line
sub recognize_line{
  my $self = shift;
  my $line = Normalize_line(shift);
  my $results = {}; # results for this line

  # start debugging regular expressions
  #use re 'debugcolor';

  my $exp = {
    # words that can be inside names
    'partOfName' => '(da|de|do|das|dos|Da|De|Do|Das|Dos)',
    # capital word
    'word' => '\p{Uppercase_Letter}\p{Lowercase_Letter}*'
  };

  # try to find names
  while( $line =~ /$exp->{word}(\s($exp->{partOfName}\s)?$exp->{word})*/g ){
    $results->{$&}{is_a} = 'name' if $&;
  }

  # stop debugging regular expressions
  #no re 'debugcolor';

  $self->add_to_entities($results);
  return 1;
}

# merges new entities with the existing entities
sub add_to_entities{
  my ($self, $results) = @_;

  foreach my $key (keys %$results) {
    if( defined $self->{entities}{$key} ){
      # TODO: handle collisions
      print STDERR "$key exists in result, overwriting."
    }else{
      $self->{entities}{$key} = $results->{$key};
    }
  }
}

# gets existing entities
sub entities{
  my $self = shift;
  return $self->{entities};
}

####################################
# Class methods

# removes unuseful parts of a line
sub Normalize_line {
  my $line = shift;

  $line =~ s/\{\}//g;
  $line =~ s/\s+/ /g;
  #join ' ', (split(/[^\w0-9()]+/, shift));

  return $line;
}

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

NameEntityRecognition - Perl extension for blah blah blah

=head1 SYNOPSIS

  use NameEntityRecognition;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for NameEntityRecognition, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

A. U. Thor, E<lt>chalkos@nonetE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2015 by A. U. Thor

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.20.1 or,
at your option, any later version of Perl 5 you may have available.


=cut

package NameEntityRecognition;

use 5.020001;
use strict;
use warnings;
use utf8::all;

require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw( Create );

our $VERSION = '0.01';


# Methods

# takes a function, a type (file or text) and a filename or text string.
# normalizes each line of the input and maps function to each normalized line
sub map_lines {
  my ($fun, $type, $value) = @_;

  if( !($type eq 'file') && !($type eq 'text') ){
    die "Second parameter must be 'file' or 'text'.";
  }

  my $in;
  my @results = ();

  my $normalized_line;

  if($type eq 'file'){
    open($in, "<", $value) or die "cannot open '$value': $!";
    while(my $line = <$in>){
      $normalized_line = join ' ', (split(/[^\w0-9()]+/, $line));
      push(@results, &$fun($normalized_line));
    }
    close($in);
  }else{
    for my $line (split /^/, $value) {
      $normalized_line = join ' ', (split(/[^\w0-9()]+/, $line));
      push(@results, &$fun($normalized_line));
    }
  }

  \@results;
}

sub Create {
  my ($type, $names, $taxonomy) = @_;

  if( !($type eq 'file') && !($type eq 'text') ){
    die "First parameter must be 'file' or 'text'.";
  }

  sub {
    my $value = shift;
    my $t = $type;
    return map_lines(\&Recognize, $t, $value);
  }
}

sub Recognize {
  my $line = shift;
  "example: $line"
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

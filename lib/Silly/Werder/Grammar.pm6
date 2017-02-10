#!/usr/bin/Perl6

use v6.c;

unit module Silly::Werder::Grammar;

my %SYLLABLES;

##########################################################################
#  Load the syllable file
##########################################################################
sub _load_syllables is export {
  my %index_syllables;

  # cw: # Determine how to load files packaged via P6.
  my $syllable_file = %?RESOURCES<grammars><syllables>.IO.slurp(
    :enc<latin1>, :close
  );

  my @syllables = $syllable_file.lines.sort({
    my $min = min($^a.chars, $^b.chars);

    $^a.lc.substr(0, $min) cmp $^b.lc.substr(0, min) ||
    $^b.chars <=> $^a.chars
  });

  # Remove (adjacent) duplicates
  @syllables = @syllables.squish;
  for @syllables -> $syl {
    my $firsttwo = $syl.substr(0, 2).lc;
    my $first = $firsttwo.substr(0, 1);
    $firsttwo = "_" if $first eq $firsttwo;
    %index_syllables{$first}{$firsttwo}.push($syl);
  }

  %SYLLABLES = %index_syllables;

  0;
}

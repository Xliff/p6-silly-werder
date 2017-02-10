# Original version Copyright 2000-2002 Dave Olszewski.
# Perl6 port Copyright 2016 by Clifton Wood
# All rights reserved.
# Perlish way to generate snoof (language which appears to be real but is
#  in fact, not)
# Distributed under the terms of GPL Version 2

use v6.c;

unit class Silly::Werder;

#use Silly::Werder::Grammar;

our $VERSION = v0.0.1;

constant SENTENCE    = '.';
constant QUESTION    = '?';
constant EXCLAMATION = '!';

has $!min_werds = 5;
has $!max_werds = 9;
has $!min_syllables = 3;
has $!max_syllables = 7;
has $!hard_syllable_max;
has $!grammar;
has $!index;

has Bool $!end_with_newline;
has Bool $!unlinked;

method new(:$min_werds, :$max_werds, :$min_syllables, :$max_syllables) {
  self.bless(:$min_werds, :$max_werds, :$min_syllables, :$max_syllables);
}

##########################################################################
#  Sets the min and max number of werds that will go into the sentence
##########################################################################
method set_werds_num(Silly::Werder:D: $min, $max) {
  return -1 if $min > $max;
  $!min_werds = $min;
  $!max_werds = $max;

  # No news is good news.
  0;
}

##########################################################################
#  Sets the min and max number of syllables that can go into a werd
##########################################################################
method set_syllables_num(Silly::Werder:D: $min, $max) {
  return -1 if $min > $max;
  $!min_syllables = $min;
  $!max_syllables = $max;

  0;
}

##########################################################################
#  Sets a hard max syllables per werd
##########################################################################
method set_hard_syllable_max(Silly::Werder:D: $max where * > 0) {
  $!hard_syllable_max = $max;

  0;
}

##########################################################################
#  Sets whether you want to end sentences in a newline
##########################################################################
method end_with_newline(Silly::Werder:D: $yesno) {
  $!end_with_newline = $yesno.Bool;

  0;
}

##########################################################################
#  Sets whether you want fully random mode or not (not recommended)
##########################################################################
method set_unlinked(Silly::Werder:D: $yesno) {
  $!unlinked = $yesno.Bool;

  0;
}

##########################################################################
#  Create a random type of sentence
##########################################################################
method line {
  do given (^3).pick {
    when 0 { .make_line(SENTENCE); }
    when 1 { .make_line(QUESTION); }
    when 2 { .make_line(EXCLAMATION); }
  }
}

##########################################################################
#  Create a sentence with a period
##########################################################################
method sentence {
  self!make_line(SENTENCE);
}

##########################################################################
#  Create a question
##########################################################################
method question {
 self!make_line(QUESTION);
}

##########################################################################
#  Create an exclamation
##########################################################################
method exclamation {
  self!make_line(EXCLAMATION);
}

##########################################################################
#  Make and return a single werd
##########################################################################
method get_werd {
  self!make_werd;
}

##########################################################################
#  Set the language/grammar to use
##########################################################################
method set_language(Silly::Werder:D: $lang, $variant?) {
  require ::("Silly::Werder::{$lang}");
  ($!grammar, $!index) = ::("Silly::Werder::{$lang}")::LoadGrammar($variant);
}

##########################################################################
#  Internal method to make a single werd
##########################################################################
method !make_werd(Silly::Werder:D:) {
  # cw: Worry about making Class calls after the rest of the port is done.
  .set_language("English") unless $.grammer.defined || $.index.defined;

  my $syl = "_BEGIN_";
  my $werd = "";
  my $which;
  my $sylcount = 0;

  # Random mode
  if $!unlinked {
    my $syl_num = ((^$!max_syllables).pick - $!min_syllables + 1) * $!min_syllables;

    for (^$syl_num) -> $i {
      repeat {
        $which = (^$!grammar.size).pick;
      } while
        $!grammar.werd($which)[0] eq '_BEGIN_' ||
        $!grammar.werd($which)[0] eq '_END';
      }

      $werd ~= $!grammar.werd($which)[0];
  } else {
    while $syl ne '_END_' {
      last if $!hard_syllable_max.defined && $sylcount >= $!hard_syllable_max;

      $which = -1;
      $werd ~= $syl if $syl ne '_BEGIN_';
      my $offset = $!index{$syl};
      my $count = +@( $!grammar.werd($offset)[1] );
      if $sylcount >= $!max_syllables - 1 {
        # Choose an ending
        $which = -1;
        for (^$count) -> $i {
          if $!grammar.werd($offset)[1][$i][0] eq '_END_' {
            $which = $i;
            last;
          }
        }
      }
      if $which < 0 {
        my ($freq_total, $freq);

        $freq_total = $!grammar.werd($offset)[2].sum;
        repeat {
          my ($freq_sum, $which_freq);

          $which_freq = (^$freq_total).pick + 1;
          for (^$!grammar.werd($offset)[2]) -> $i {
            $freq_sum += $!grammar.werd($offset)[2][$i];
            if $freq_sum >= $which_freq {
              $which = $i;
              last;
            }
          }
        } while (
          $!grammar.werd($offset)[1][$which][0] eq '_END_'  &&
          $count > 1                                        &&
          $sylcount < $!min_syllables
        );
      }

      $syl = $!grammar.werd($offset)[1][$which][0];
      $sylcount++;
    }
  }

  $werd;
}

method !make_line(Silly::Werder:D: $ending?) {
  my ($line, $num_werds, $werd_counter);

  $num_werds = ((^$!max_werds).pick - $!min_werds + 1) + $!min_werds;
  for (^$num_werds) -> $werd_counter {
    $line ~= " { .self!make_werd }";
  }

  $line.substr-rw(2, 1) = $line.substr(2, 1).uc;
  $line ~= $ending if $ending.defined;
  $line ~= "\n" if $!end_with_newline;

  $line;
}

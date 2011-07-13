#!/usr/bin/perl -w

use perl5i::2;
use Moose;

open my $name_mismatches, '>', 'mismatches.txt' or die;
open my $unknown_term_names, '>', 'unknown_term_names.txt' or die;
open my $ortholog_problems, '>', 'ortholog_problems.txt' or die;
open my $qual_problems, '>', 'qualifier_problems.txt' or die;
open my $unknown_cv_names, '>', 'unknown_cv_names.txt' or die;
open my $mapping_problems, '>', 'mapping_problems.txt' or die;
open my $cv_name_mismatches, '>', 'cv_name_mistaches.txt' or die;
open my $duplicated_sub_qual_problems, '>', 'duplicated_sub_qual_problems.txt' or die;
open my $all_warnings, '>', 'all_warnings.txt' or die;

my $prev_line = '';
my $gene = '';

while (defined (my $line = <>)) {
  if ($line =~ /ID in EMBL file/) {
    print $all_warnings "$line";
    print $name_mismatches "$gene: $line";
  } else {
    if ($line =~ /found cvterm by ID/) {
      print $all_warnings "$line";
      print $unknown_term_names "$gene: $line";
    } else {
      if ($line =~ /ortholog.*not found/) {
        print $all_warnings "$line";
        print $ortholog_problems "$gene: $line";
      } else {
        if ($line =~ /didn't process: /) {
          print $all_warnings "$line";
          chomp $prev_line;
          chomp $line;
          print $qual_problems "$gene: $line  - error: $prev_line\n";
        } else {
          if ($line =~ /CV name not recognised/) {
            print $all_warnings "$line";
            print $unknown_cv_names "$gene: $line";
          } else {
            if ($line =~ /no term for:|qualifier not recognised/) {
              print $all_warnings "$line";
              print $qual_problems "$gene: $line";
            } else {
              if ($line =~ /can't find new term for .* in mapping/) {
                print $all_warnings "$line";
                print $mapping_problems "$gene: $line";
              } else {
                if ($line =~ /^processing (.*)/) {
                  $gene = $1;
                } else {
                  if ($line =~ /duplicated sub-qualifier '(.*)'/) {
                    $line =~ s/^\s+//;
                    $line =~ s/\s*from:\s*//;
                    print $all_warnings "$line\n";
                    print $duplicated_sub_qual_problems "$gene: $line\n";
                  } else {
                    if ($line =~ /cv_name .* doesn't match start of term .*/) {
                      print $all_warnings "$line";
                      print $cv_name_mismatches "$gene: $line";
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  $prev_line = $line;
}

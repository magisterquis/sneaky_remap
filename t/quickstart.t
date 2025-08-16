#!/usr/bin/env perl
#
# quickstart.t
# Make sure the README's Quickstart sections are correct.
# By J. Stuart McMurray
# Created 20250725
# Last Modified 20250816

use autodie;
use feature 'signatures';
use strict;
use warnings;

use Test::More tests => 2;


# Find line reads $f until $line is found.  It returns true if the line was
# found, false otherwise.  If not found, the file will have been entirely
# read. and $F won't give you much.
sub find_line ($f, $line) {
        while (<$f>) {
                chomp;
                return 1 if ($line eq $_);
        }
        return 0;
}

# check_quickstart checks the quickstart section $section for source in
# language $lang, then makes sure there's a suitable example.
sub check_quickstart($section, $lang) {
        plan tests => 3;
        my $example_file = "examples/quickstart_$lang/quickstart_$lang.$lang";

        # Open the README.
        open my $F, "<", "README.md";

        # Find the start of the quickstart section.
        ok find_line($F, $section), "Found the $section section";

        # Find the source.
        ok find_line($F, "   ```$lang"), "Found the $lang source";

        # Get the block up to the end of the fence, less leading spaces.
        my $got = '';
        while (<$F>) {
                last if $_ eq "   ```\n";
                s/^   //;
                $got .= $_;
        }

        # Get the non-comment code from the source file.
        open my $S, "<", $example_file;
        my $want = '';
        my $last = '';
        while (<$S>) {
                # Skip comments.
                next if m,^(//|/\*| \* | \*/),;
                # Compress multiple blank lines.
                next if ("\n" eq $_ and $_ eq $last);
                $want .= $_;
                $last  = $_;
        }

        # Trim leading and trailing blank lines.
        $got  =~ s/(^\n+|\n+$)//gs;
        $want =~ s/(^\n+|\n+$)//gs;

        # Do they match?
        is $got, $want, "$section code is the same as in $example_file";
}

subtest "Quickstart (Go)", \&check_quickstart, "Quickstart (Go)", "go";
subtest "Quickstart (C)",  \&check_quickstart, "Quickstart (C)",  "c";

done_testing;

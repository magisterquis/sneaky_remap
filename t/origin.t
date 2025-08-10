#!/bin/ksh
#
# origin.t
# Make sure we're using our origin in Go files
# By J. Stuart McMurray
# Created 20250810
# Last Modified 20250810

set -euo pipefail

. t/shmore.subr

# Figure out what files need to be checked
set -A GOFILES $(find . -name '*.go' -exec grep -lF '_ "github.com/' {} +)

# One for the origin, one for each source file, two for go.mod.
tap_plan $((1 + 2 + ${#GOFILES[@]}))

# Work out our own origin.
ORIGIN=$(
        perl -ne '
                next unless $_ eq "[remote \"origin\"]\n";
                $_=<>;
                s/(^[^@]+@|\.git$)//g;
                s/:/\//;
                print
        ' .git/config
)
tap_isnt "$ORIGIN" "" "Found origin URL" "$0" $LINENO
tap_note "Origin: $ORIGIN"

# Make sure go.mod is correct.
WANT="module $ORIGIN"
set +e
GOT=$(head -n1 go.mod)
RET=$?
set -e
tap_ok  $RET          "Read go.mod"                   "$0" $LINENO
tap_is "$WANT" "$GOT" "Module line in go.mod correct" "$0" $LINENO


# Should be in any Go files that pull from GitHub.
for FN in "${GOFILES[@]}"; do
        set +e
        grep -qF "_ \"$ORIGIN\"" "$FN"
        RET=$?
        set -e
        tap_ok $RET "Correct import $ORIGIN found in $FN" "$0" $LINENO
done


# vim: ft=sh

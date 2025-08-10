#!/bin/ksh
#
# readme_theory.t
# Make examples for the Theory section in the main README.md
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250728

set -euo pipefail

. ./t/shmore.subr

tap_plan 10

# Filenames in play
LIB=readme_theory.so
LOADER=maps_before_and_after
MAPS_AFTER=maps_after
MAPS_BEFORE=maps_before
MAPS_DURING=maps_during
US_AFTER=us_after
US_BEFORE=us_before

# Assemble all the parts into a temporary directory and be in there.
TMPD=$(mktemp -d)
trap 'rm -rf "$TMPD"; tap_done_testing' EXIT
cp sneaky_remap.c sneaky_remap.h "$TMPD" # The sneaky_remap source
cp t/testdata/$(basename ${0%.t})/{Makefile,*.{c,patch}} "$TMPD" # Needed files from this directory
cd "$TMPD"

# Build the code.
set +e
bmake
tap_ok $? "Make exited happily" "$0" $LINENO
[[ -f "$LIB" ]]
tap_ok $? "Library $LIB built" "$0" $LINENO
[[ -f "$LOADER" ]]
tap_ok $? "Loader $LOADER built" $0 $LINENO
set -e
if [[ ! -f "$LIB" || ! -f "$LOADER" ]]; then
        tap_diag "Missing files, bailing"
        exit 10
fi

# Run it to get the mapped files.
set +e
GOT=$("./$LOADER" 2>&1)
RET=$?
set -e
tap_ok  $?       "Loader $LOADER ran happily" "$0" $LINENO
tap_is "$GOT" "" "Loader $LOADER ran quietly" "$0" $LINENO
if [[ 0 -ne $RET ]]; then
        tap_diag "Loader failed, bailing"
        exit 11
fi

# Get the bits we need.
grep -E "$PWD/$LIB\$" "$MAPS_BEFORE" >"$US_BEFORE"
tap_ok $? "Found our lines in $MAPS_BEFORE" "$0" $LINENO

# Work out what we'll need in the AFTER file.
RANGES=$(awk '{print $1}' "$US_BEFORE")
NRANGES=$(echo -E "$RANGES" | wc -l)
tap_isnt "$NRANGES" 0 "Found our mapped memory ranges" "$0" $LINENO

# Find our ranges in the after file.
subtest() {
        tap_plan "$NRANGES"
        typeset _range
        for _range in $RANGES; do
                subtest() {
                        tap_plan 2
                        # Make sure we got the right range.
                        typeset _got=$(grep -F "$_range" "$US_BEFORE" ||:)
                        tap_like \
                                "$_got" '^(\S+(\s+)){5}\S+' \
                                "Mapped file found before hiding" \
                                "$0" $LINENO
                        _got=$(grep -F "$_range" "$MAPS_AFTER" ||:)
                        tap_unlike \
                                "$_got" '^(\S+(\s+)){5}\S+' \
                                "Mapped file not found after hiding" \
                                "$0" $LINENO
                        print -r "$_got" >>"$US_AFTER"
                }
                tap_subtest "Range $_range hidden" subtest "$0" $LINENO
        done
}
tap_subtest "Hidden in all mapped ranges" subtest "$0" $LINENO

# Make sure before, during, and after files are the same length
BEFORELEN=$(($(wc -l <$US_BEFORE)))
DURINGLEN=$(($(wc -l <$MAPS_DURING)))
AFTERLEN=$(($(wc -l <$US_AFTER)))
tap_is \
        "$AFTERLEN" "$BEFORELEN" \
        "Same number of maps before and after" \
        "$0" $LINENO
tap_is \
        "$DURINGLEN" "$BEFORELEN" \
        "Same number of intermediate maps as mapped file ranges" \
        "$0" $LINENO

# And now, the moment you've all been waiting for...
tap_note "Ranges before"
tap_note "-------------"
tap_note "$(<"$US_BEFORE")"
tap_note "Intermediate ranges"
tap_note "-------------------"
tap_note "$(<"$MAPS_DURING")"
tap_note "Ranges after"
tap_note "-------------"
tap_note "$(<"$US_AFTER")"

# vim: ft=sh

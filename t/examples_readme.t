#!/bin/ksh
#
# readme.t
# Make sure our README isn't missing anything
# By J. Stuart McMurray
# Created 20250809
# Last Modified 20250816

set -euo pipefail

. t/shmore.subr

EDIR=examples
README=$EDIR/README.md

# Directories we expect to be present.
set -A DIRS $({
        find "$EDIR" -maxdepth 1 -type d \! -name "$EDIR" | cut -f 2- -d / &&
        grep -Eo '^\[`[^`]+`\]' $README | cut -f 2 -d '`'
} | sort -u)
NDIRS=${#DIRS[@]}

tap_plan $((3 + (2 * $NDIRS)))

# Make sure they are.
tap_isnt "$NDIRS" 0 "Found examples directories" "$0" $LINENO
for DIR in "${DIRS[@]}"; do
        # Is the directory a directory?
        set +e
        [[ -d "$EDIR/$DIR" ]]
        RET=$?
        set -e
        tap_ok $RET "$EDIR/$DIR exists" "$0" $LINENO
        # Is it in the readme?
        set +e
        grep -Eq '^\[`'"$DIR"'`\]' "$README"
        RET=$?
        set -e
        tap_ok $RET "$DIR listed in $README" "$0" $LINENO
done

# Make sure lines are sorted
START=$(grep -En -- '^-+\|-+$' "$README" | cut -f 1 -d :)
tap_isnt "$START" "" "Found the start of the list" "$0" $LINENO
GOT=$(tail -n "+$(($START +1))" "$README")
WANT=$(echo "$GOT" | sort -u)
tap_is "$GOT" "$WANT" "Directory list is sorted" "$0" $LINENO


# vim: ft=sh

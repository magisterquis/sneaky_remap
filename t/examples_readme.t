#!/bin/ksh
#
# readme.t
# Make sure our README isn't missing anything
# By J. Stuart McMurray
# Created 20250809
# Last Modified 20250809

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

# Make sure they are.
tap_plan $((1 + (2 * $NDIRS)))
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
        egrep -q '^\[`'"$DIR"'`\]' "$README"
        RET=$?
        set -e
        tap_ok $RET "$DIR listed in $README" "$0" $LINENO
done


# vim: ft=sh

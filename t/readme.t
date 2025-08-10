#!/bin/ksh
#
# readme.t
# Make sure our README isn't missing anything
# By J. Stuart McMurray
# Created 20250809
# Last Modified 20250809

set -euo pipefail

. t/shmore.subr

README=README.md

# Make sure every directory has a readme.
set -A DIRS $(find .\
        -type d \
        \! -path './.git'         \
        \! -path './.git/*'       \
        \! -path './examples/*/t' \
        \! -path './t/testdata/*' |
        sort -u)
NDIRS=${#DIRS[@]}

tap_plan $((1 + $NDIRS))

# Make sure we actually found directories.
tap_cmp_ok $NDIRS -gt 0 "Found $NDIRS directories" "$" $LINENO

# Make sure each directory has a README
set -A MISSING
for DIR in "${DIRS[@]}"; do
        set +e
        [[ -f "$DIR/$README" ]]
        RET=$?
        set -e
        tap_ok $RET "$README found in $DIR" "$0" $LINENO
        if [[ 0 -ne $RET ]]; then
                set -A MISSING "${MISSING[@]}" "$DIR"
        fi
done

# Note the missing directories if we have any.
if [[ 0 -ne ${#MISSING[@]} ]]; then
        tap_diag "Directories without a $README:"
        for DIR in "${MISSING[@]}"; do
                tap_diag "    $DIR"
        done
fi

# vim: ft=sh

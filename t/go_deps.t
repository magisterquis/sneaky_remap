#!/bin/ksh
#
# go_deps.t
# Make sure we have no go dependencies
# By J. Stuart McMurray
# Created 20250730
# Last Modified 20250804

set -euo pipefail

. ./t/shmore.subr

# Find all of the go.mod files, four tests per file
FS=$(find . -name go.mod -type f)
tap_plan $((1 + ($(echo "$FS" | wc -l) * 4)))

# Make sure every file has no dependencies.
for F in $FS; do
        # Should have a module name, a blank line, and a go version, that's it.
        LC=$(wc -l "$F" | awk '{print $1}')
        tap_is "$LC" 3 "$F - Correct number of lines" "$0" $LINENO

        # Make sure the lines are correct.
        set +e
        {
                # Module line first.
                read
                tap_like \
                        "$REPLY" '^module ' \
                        "$F - First line is the module directive" \
                        "$0" $LINENO

                # Blank in the middle.
                read
                tap_is "$REPLY" "" "$F - Blank line in the middle" "$0" $LINENO

                # Go version last
                read
                tap_like \
                        "$REPLY" '^go \d+\.\d+\.\d+$' \
                        "$F - Third line is the Go version"\
                        "$0" $LINENO
        } <"$F"
        set -e
done

# Shouldn't have any go.sum files.
GOT=$(find . -name go.sum)
tap_is "$GOT" "" "No go.sum files" "$0" $LINENO


# vim: ft=sh

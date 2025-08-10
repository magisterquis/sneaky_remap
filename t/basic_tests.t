#!/bin/ksh
#
# basic_tests.t
# Make sure our code is up-to-date and doesn't have debug things.
# By J. Stuart McMurray
# Created 20250725
# Last Modified 20250810

set -uo pipefail

. t/shmore.subr

NTEST=5
tap_plan "$NTEST"

# Make sure we didn't leave any stray DEBUGs or TAP_TODOs lying about.
GOT=$(grep -EInR '(#|\*|^)[[:space:]]*()DEBUG' | sort -u)
tap_is "$GOT" "" "No files with DEBUG comments" "$0" $LINENO
GOT=$(grep -EInR '(#|\*|^)[[:space:]]*()TODO' | sort -u |
        grep -Ev '^(\.git/hooks/[^:]+\.sample|t/shmore.subr):[[:digit:]]+:')
tap_is "$GOT" "" "No files with TODO comments" "$0" $LINENO
GOT=$(grep -EIn  'TAP_TODO[=]' t/*.t | sort -u)
tap_is "$GOT" "" "No TAP_TODO's" "$0" $LINENO

# These checks assume we're writing a Go program.
if [[ -f ./go.mod ]]; then
        # Make sure we don't need to update anything.
        GOT="$(go list \
                -u \
                -f '{{if (and (not (or .Main .Indirect)) .Update)}}
                        {{- .Path}}: {{.Version}} -> {{.Update.Version -}}
                {{end}}' \
                -m all)"
        tap_is "$GOT" "" "Packages up-to-date" "$0" $LINENO
        # Idea stolen from https://github.com/fogfish/go-check-updates

        # Make sure we're using the latest Go as well.
        GOT="$(go list \
                -u \
                -f '{{if (and .Update .Update.Version) -}}
                        go {{.Version}} -> {{.Update.Version}}
                {{- end}}' \
                -m go)"
        tap_is "$GOT" "" "Latest Go version will be used" "$0" $LINENO
else
        tap_skip "Not a Go program" $((NTEST-2))
fi

# vim: ft=sh

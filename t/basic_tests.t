#!/bin/ksh
#
# basic_tests.t
# Make sure our code is up-to-date and doesn't have debug things.
# By J. Stuart McMurray
# Created 20250725
# Last Modified 20251005

set -uo pipefail

. t/shmore.subr

# OK_DEBUG and OK_TODO, if exant, contain grep output lines to be ignored
# in the first two tests.
OK_DEBUG=t/testdata/basic_tests/debug_ok
OK_TODO=t/testdata/basic_tests/todo_ok

# Make sure we didn't leave any stray DEBUGs or TAP_TODOs lying about.
GOT=$(grep -EInR '(#|\*|^)[[:space:]]*()DEBUG' | sort -u |
        grep -Ev '^t/shmore.subr:[[:digit:]]+:' |
        grep -Ev "^$OK_DEBUG:[[:digit:]]+" ||:)
if [[ -f "$OK_DEBUG" ]]; then
        GOT=$(print -r "$GOT" | grep -Fvf "$OK_DEBUG" ||:);
fi
tap_is "$GOT" "" "No files with unexpected DEBUG comments" "$0" $LINENO
GOT=$(grep -EInR '(#|\*|^)[[:space:]]*()TODO' | sort -u |
        grep -Ev '^(\.git/hooks/[^:]+\.sample|t/shmore.subr):[[:digit:]]+:' |
        grep -Ev "^$OK_DEBUG:[[:digit:]]+" ||:)
if [[ -f "$OK_TODO" ]]; then
        GOT=$(print -r "$GOT" | grep -Fvf "$OK_TODO" ||:);
fi
tap_is "$GOT" "" "No files with unexpected TODO comments" "$0" $LINENO
GOT=$(grep -EIn  'TAP_TODO[=]' t/*.t | sort -u ||:)
tap_is "$GOT" "" "No TAP_TODO's" "$0" $LINENO

# vim: ft=sh

#!/bin/ksh
#
# quickstart_go.t
# Example of using Go to quickly start
# By J. Stuart McMurray
# Created 20250811
# Last Modified 20250816

set -euo pipefail

. ./t/shmore.subr

tap_plan 4

# Run the example
set +e
OUT=$(bmake -C "${0%/t/*}" -s run 2>&1 | grep -Ev 'bash: line 1: enable: ')
RET=$?
set +x
tap_ok "$?" "Make exited happily" "$0" $LINENO

# Make sure it looks correct.
tap_isnt "$OUT" "" "Got output" "$0" $LINENO
GOT=$(print -r "$OUT" | head -n 2)
WANT='Post-Hiding Mapped Memory
-------------------------'
tap_is "$GOT" "$WANT" "Output header correct" "$0" $LINENO
GOT=$(print -r "$GOT" |
        tail -n +3 |
        grep -Ev '^[[:xdigit:]]+-[[:xdigit:]]+ [r-][w-][x-]p [[:xdigit:]]+ [[:xdigit:]]{2}:[[:xdigit:]]{2} [[:digit:]]+[[:space:]]+' 2>&1)
tap_is "$GOT" "" "Output body looks like /proc/pid/maps" "$0" $LINENO

# vim: ft=sh

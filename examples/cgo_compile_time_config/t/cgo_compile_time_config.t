#!/bin/ksh
#
# cgo_compile_time_config.t
# Example of using Go to quickly start
# By J. Stuart McMurray
# Created 20250816
# Last Modified 20250816

set -euo pipefail

. ./t/shmore.subr

tap_plan 6

LIB=cgo_compile_time_config.so

# Run the example.
OUT=$(bmake -C ${0%/t/*} 2>&1)

# Should have an equal number of Map to hide and Remapping lines
MTH=$(($(print -r "$OUT" | grep -E '^Map to hide:' | wc -l ||:)))
REM=$(($(print -r "$OUT" | grep -E '^Remapping 0x' | wc -l ||:)))
tap_cmp_ok "$MTH" '-gt' 0 'Got "Map to hide:" lines' "$0" $LINENO
tap_cmp_ok "$REM" '-gt' 0 'Got "Remapping"    lines' "$0" $LINENO
tap_is \
        "$MTH" "$REM" \
        'Got an equal number of "Map to hide:" and "Remapping" lines' \
        "$0" $LINENO

# Should have a before and after loading listing
set +e
print -r "$OUT" | grep -Eq "^Before loading: .* $LIB\$";
RET=$?
set -e
tap_ok $RET "Found library before loading";
set +e
print -r "$OUT" | grep -qF \
        "ls: cannot access 'cgo_compile_time_config.so': No such file or directory";
RET=$?
set -e
tap_ok $RET "Found no library after lodaing";
set +e

# Should end in a Done.
GOT=$(print -r "$OUT" | tail -n 1)
WANT="Done."
tap_is "$GOT" "$WANT" "Ended with $WANT" "$0" $LINENO

# vim: ft=sh

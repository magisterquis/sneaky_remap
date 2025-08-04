#!/bin/ksh
#
# debug_strings.t
# Make sure we didn't leave any debug strings in without SREM_DEBUG.
# By J. Stuart McMurray
# Created 20250729
# Last Modified 20250730

set -euo pipefail

. t/shmore.subr

tap_plan 3

LIB=lib.so

# Temporary directory for our buildy things.
TMPD=$(mktemp -d)
trap 'rm -rf $TMPD; tap_done_testing' EXIT
cp sneaky_remap.c sneaky_remap.h "$TMPD"
cd "$TMPD"

# From here we'll want to see things fail.
set +e

# Build the library without debug things.
cc --pedantic -O2 -Wall -Werror -Wextra -fPIC -shared -o "$LIB" sneaky_remap.c
tap_is $? 0 "Built happily" "$0" $LINENO

# Get just the .rodata section, which seems to be where strings live.
objcopy -O binary --only-section=.rodata "$LIB" 
tap_is $? 0 "Extracted .rodata happily" "$0" $LINENO

# Should only have two predictable strings.
GOT=$(sort -z $LIB | hexdump -C)
WANT=$(cat <<'_eof'
00000000  25 6c 78 2d 25 6c 78 20  25 34 63 20 25 2a 73 20  |%lx-%lx %4c %*s |
00000010  25 2a 73 20 25 2a 73 20  25 34 30 39 36 5b 01 2d  |%*s %*s %4096[.-|
00000020  ff 5d 00 2f 70 72 6f 63  2f 73 65 6c 66 2f 6d 61  |.]./proc/self/ma|
00000030  70 73 00                                          |ps.|
00000033
_eof
)
tap_is "$GOT" "$WANT" "No new strings added" "$0" $LINENO

# vim: ft=sh

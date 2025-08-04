#!/bin/ksh
#
# debug_output.t
# Check that debug output looks right in the happy case
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250728

set -euo pipefail

. t/test_loader.subr

tap_plan 3

# Build and load the library, making sure the thread ran.
export CFLAGS=-DSREM_DEBUG
test_loader "" $LINENO

# Work out what the debug messages should be.
LP="$TMPD/$LIB"
NFOUND=0
REMAPS=""
awk -v LP="$TMPD/$LIB" '
        $6 == LP {
                sub(/-/, " ", $1)
                prot = 0
                if ($2 ~ /r/) { prot += 1 }
                if ($2 ~ /w/) { prot += 2 }
                if ($2 ~ /x/) { prot += 4 }
                print $1, prot
        }
' maps_loaded |
while read START END PROT; do
        START=$((0x$START))
        END=$((0x$END))
        PROT=$((0x$PROT))
        LEN=$((END-START))
        printf \
                'Map to hide: start:0x%x len:0x%x prot:0x%x path:%s\n' \
                $START \
                $LEN   \
                $PROT  \
                "$LP"
        : $((NFOUND++))
        REMAPS="$REMAPS$(printf 'Remapping 0x%x bytes for 0x%x...ok :)\n' \
                $LEN \
                $START)
"
done                                              >want
echo    "Found ourselves in $LP in $NFOUND maps" >>want
echo -n "$REMAPS"                                >>want
echo    "Invisibility cloak active!!!"           >>want

# Did it work?
GOT="$(<loader_stderr)"
WANT="$(<want)"
tap_is "$GOT" "$WANT" "Debug messages correct" "$0" $LINENO

# vim: ft=sh

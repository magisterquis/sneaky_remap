#!/bin/ksh
#
# maps_files.t
# Make sure we're not obviously visible in several maps files in /proc
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250730

set -euo pipefail

. t/test_loader.subr

# MAP_FILES are files copied from /proc where we may find our libray listed.
MAP_FILES="map_files maps_inlib numa_maps smaps"

tap_plan $((2 + $((2 * $(echo -n "$MAP_FILES" | wc -w)))))

# Build and load the library.
test_loader "" $LINENO

# Make sure hiding made us invisible.
for F in $MAP_FILES; do
        # Were we visible to begin with?
        FN=${F}_before
        GOT=$(grep "$TMPD/$LIB" "$FN" ||:)
        tap_isnt "$GOT" "" "$FN - Visible before hiding" "$0" $LINENO

        # Were we visible after hiding?
        FN=${F}_after
        GOT=$(grep "$TMPD/$LIB" "$FN" ||:)
        tap_is "$GOT" "" "$FN - Visible after hiding" "$0" $LINENO
done

# vim: ft=sh

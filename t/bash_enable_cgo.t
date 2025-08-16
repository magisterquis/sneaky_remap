#!/bin/ksh
#
# bash_enable_cgo.t
# Test running a self-hiding Go library with a thread, with go get
# By J. Stuart McMurray
# Created 20250730
# Last Modified 20250816

set -euo pipefail

. t/test_loader.subr

tap_plan 5

SCRIPT=run.sh
MSG="Line from environment"

# Build our library
test_loader "" $LINENO

# Make sure the library works as a background thread in Bash.
set +e
GOT=$(MSG="$MSG" bash -s "$LIB" "$MAPS_BEFORE" "$MAPS_AFTER" <"$SCRIPT" 2>&1)
RET=$?
GOT=$(echo "$GOT" | grep -Ev "^bash: line 24: enable:") # Whiny...
set -e
WANT="$MSG 9"
tap_is  $RET   0      "Bash script with enable exited happily" "$0" $LINENO
tap_is "$GOT" "$WANT" "Go thread ran"                          "$0" $LINENO

# Make sure we didn't sprout any mapped files while running in Bash.
no_new_mapped_files \
        "$MAPS_BEFORE" "$MAPS_AFTER" \
        "No new mapped files after enabling in Bash" \
        $LINENO

# vim: ft=sh

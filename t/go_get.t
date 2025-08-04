#!/bin/ksh
#
# go_get.t
# Test hiding with go get
# By J. Stuart McMurray
# Created 20250730
# Last Modified 20250730

set -euo pipefail

. t/test_loader.subr

tap_plan 14

# Build and load the library.
WANT='In init
In sowait'
test_loader "$WANT" $LINENO
tap_pass "Library with no config worked"

# Build it with debugging.
rm "$LIB"
export CGO_CFLAGS=-DSREM_DEBUG
WANT='In init
In sowait'
test_loader "$WANT" $LINENO
tap_pass "Debug library worked"

# Make sure we get debugging output.
GOT=$(tail -n1 <"$LOADER_STDERR")
WANT='Invisibility cloak active!!!'
tap_is "$GOT" "$WANT" "Debug library producted debugging output" "$0" $LINENO

# Build it such that it removes itself.
rm "$LIB"
export CGO_CFLAGS=-DSREM_CGO_START_FLAGS=SREM_SRS_UNLINK
WANT='In init
In sowait'
test_loader "$WANT" $LINENO
tap_pass "Self-removing library worked"

# See if the library was removed.
set +e
[[ ! -f "$LIB" ]];
RET=$?
set -e
tap_ok $RET "Self-removing library unlinked itself" "$0" $LINENO

# vim: ft=sh

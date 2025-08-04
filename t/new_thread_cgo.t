#!/bin/ksh
#
# new_thread_cgo.t
# Test running self-hiding Go library with a thread, with go get
# By J. Stuart McMurray
# Created 20250730
# Last Modified 20250730

set -euo pipefail

. t/test_loader.subr

tap_plan 10

# Build and load the library, with a thread.
export CGO_CFLAGS="-DSREM_CGO_START_ROUTINE=doit"
WANT='In init
Context done
Thread finished'
test_loader "$WANT" $LINENO
tap_pass "Library with thread worked"

# Make sure the library didn't remove itself without SREM_SRS_UNLINK.
set +e
[[ -f "$LIB" ]];
RET=$?
set -e
tap_ok $RET "Library with thread didn't unlink itself" "$0" $LINENO

# Build and load the library, start a thread, and remove the library.
rm "$LIB"
export CGO_CFLAGS="-DSREM_CGO_START_ROUTINE=doit \
        -DSREM_CGO_START_FLAGS=SREM_SRS_UNLINK"
WANT='In init
Context done
Thread finished'
test_loader "$WANT" $LINENO
tap_pass "Library with thread worked"

# See if the library was removed.
set +e
[[ ! -f "$LIB" ]];
RET=$?
set -e
tap_ok $RET "Self-removing library with thread unlinked itself" "$0" $LINENO

# vim: ft=sh

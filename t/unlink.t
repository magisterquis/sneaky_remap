#!/bin/ksh
#
# unlink.t
# Make sure SREM_SRS_UNLINK works.
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250816

set -euo pipefail

. t/test_loader.subr

tap_plan 8

# Build and load the library.
test_loader "" $LINENO

# Library should be there the first time.
set +e
[[ -f "$LIB" ]]
RET=$?
set -e
tap_ok $RET "Non-SREM_SRS_UNLINK library $LIB not removed on load" "$0" $LINENO

# Remove the old library.
rm "$LIB"
set +e
[[ ! -f "$LIB" ]]
RET=$?
set -e
tap_ok $RET "Non-SREM_SRS_UNLINK library $LIB removed" "$0" $LINENO

# Make a new one with SREM_SRS_UNLINK.
export CFLAGS=-DSRSFLAGS=SREM_SRS_UNLINK
bmake -f ./common.mk "$LIB"
set +e
[[ -f "$LIB" ]]
RET=$?
set -e
tap_ok $RET "SREM_SRS_UNLINK library $LIB created" "$0" $LINENO

# See if it's removed properly.
"./$LOADER" "./$LIB"
set +e
[[ ! -f "$LIB" ]]
RET=$?
set -e
tap_ok $RET "SREM_SRS_UNLINK $LIB removed on load" "$0" $LINENO

# Make another new one with SREM_SRS_UNLINK for bash.
export CFLAGS=-DSRSFLAGS=SREM_SRS_UNLINK
bmake -f ./common.mk "$LIB"
set +e
[[ -f "$LIB" ]]
RET=$?
set -e
tap_ok $RET "SREM_SRS_UNLINK library $LIB created for bash" "$0" $LINENO

# Make sure it unlinks when loaded in bash as well.
LIB="$LIB" bash <<'_eof'
        ! enable "./$LIB" 2>&1 |
                grep -Ev "^bash: line 1: enable:" >&2
_eof
set +e
[[ ! -f "$LIB" ]]
RET=$?
set -e
tap_ok $RET "SREM_SRS_UNLINK $LIB removed on bash enable" "$0" $LINENO


# vim: ft=sh

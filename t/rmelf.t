#!/bin/ksh
#
# unlink.t
# Make sure SREM_SRS_UNLINK works.
# By J. Stuart McMurray
# Created 202500816
# Last Modified 20250816

set -euo pipefail

. t/test_loader.subr

tap_plan 6

# Build and load the library.
test_loader "Found an ELF header" $LINENO
tap_diag "$(<$LOADER_STDERR)"

# Try again, removing ELF headers.
rm lib.so # Force a rebuild
export CGO_CFLAGS=-DSREM_CGO_START_FLAGS=SREM_SRS_RMELF
test_loader "Found no ELF headers" $LINENO
tap_diag "$(<$LOADER_STDERR)"

# vim: ft=sh

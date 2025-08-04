#!/bin/ksh
#
# filename_with_spaces.t
# Make sure it works even if our library has spaces in it
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250728

set -euo pipefail

. t/test_loader.subr

tap_plan 4

SLIB="lib with spaces.so" # $LIB, but with spaces

# Build and load the library.
test_loader "" $LINENO

# Now try again with spaces.
cp "$LIB" "$SLIB"
set +e
"./$LOADER" "./$SLIB"
tap_is $? 0 \
        "Loader exited happily with a library name with spaces" \
        "$0" "$_lineno"
set -e

no_new_mapped_files \
        "$MAPS_BEFORE" "$MAPS_AFTER" \
        "No new mapped files with a library name with spaces" \
        "$LINENO"

# vim: ft=sh

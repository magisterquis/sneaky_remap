#!/bin/ksh
#
# run.sh
# Test running a self-hiding Go library with a thread, with go get
# By J. Stuart McMurray
# Created 20250816
# Last Modified 20250816

set -euo pipefail

LIB=$1
MAPS_BEFORE=$2
MAPS_AFTER=$3
COUNTER_FILE=counter

# Memory map before we load the library.
cat </proc/$$/maps >"$MAPS_BEFORE"

# Open a couple of pipes for Go to tell us when it's ready and done.
exec 4<> <(:)
exec 5<> <(:)

# Load the library.
! enable "./$LIB"

# Wait for the library to start.
: $(</dev/fd/4)

# Wait for the library to end.  We do this in another step to make it a bit
# more obvious if the library crashes the shell while running.
: $(</dev/fd/5)

# Caller will check the contents.  Should be 10.
cat "$COUNTER_FILE"

# Memory map after we load the library.
cat </proc/$$/maps >"$MAPS_AFTER"

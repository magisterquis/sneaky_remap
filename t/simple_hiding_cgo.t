#!/bin/ksh
#
# simple_hiding_cgo.t
# Test hiding with go by just copy/pasting the library
# By J. Stuart McMurray
# Created 20250730
# Last Modified 20250730

set -euo pipefail

. t/test_loader.subr

tap_plan 3

# Build and load the library.
WANT='In constructor
In init
In sowait'
test_loader "$WANT" $LINENO

# vim: ft=sh

#!/bin/ksh
#
# new_thread.t
# Test making a new thread
# By J. Stuart McMurray
# Created 20250725
# Last Modified 20250728

set -euo pipefail

. t/test_loader.subr

tap_plan 3

# Build and load the library, making sure the thread ran.
test_loader "In thread" $LINENO

# vim: ft=sh

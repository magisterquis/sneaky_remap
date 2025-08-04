#!/bin/ksh
#
# simple_hiding.t
# Test a very simple case of hiding
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250730

set -euo pipefail

. t/test_loader.subr

tap_plan 2

# Build and load the library.
test_loader "" $LINENO

# vim: ft=sh

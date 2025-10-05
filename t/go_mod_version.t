#!/bin/ksh
#
# go_version.t
# Make sure the go version in go.mod works with the current Go version
# By J. Stuart McMurray
# Created 20251005
# Last Modified 20251005

set -euo pipefail

. t/test_loader.subr

tap_plan 3

WANT="In sowait"
test_loader "$WANT" "$LINENO"

# vim: ft=sh

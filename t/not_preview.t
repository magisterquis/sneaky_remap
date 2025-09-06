#!/bin/ksh
#
# not_preview.t
# Make sure we're no longer sneaky_remap_preview
# By J. Stuart McMurray
# Created 20250906
# Last Modified 20250906

set -euo pipefail

. ./t/shmore.subr

tap_plan 1

GOT=$(grep -r sneaky_remap_preview | egrep -v "$(basename "$0")" ||:)
tap_is "$GOT" "" "No files with sneaky_remap_preview" "$0" $LINENO

# vim: ft=sh

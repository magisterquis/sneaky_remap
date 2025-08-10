#!/bin/ksh
#
# api_docs.t
# Make sure API is documented
# By J. Stuart McMurray
# Created 20250809
# Last Modified 20250809

set -euo pipefail

. ./t/shmore.subr

# Files in which we expect to find macros.
set -A FILES sneaky_remap.h README.md
NFILES=${#FILES[@]}

# Get ALL the macros!
set -A MACROS $(grep -Eho 'SREM_[A-Z_]*[A-Z]' "${FILES[@]}" | sort -u)
NMACROS=${#MACROS[@]}

# One for the list, one for each file itself, one for each macro in each file.
tap_plan $((1 + $NFILES + ($NFILES * $NMACROS)))

# Make sure we actually found macros.
tap_cmp_ok \
        $NMACROS -gt 0 \
        "Found $NMACROS SREM_* macros in: ${FILES[@]}" \
        "$0" $LINENO

# Make sure each macro is somewhere in the README and the header file.
for FN in "${FILES[@]}"; do
        set -A MISSING
        echo "NMISSING: ${#MISSING[@]}"
        for MACRO in "${MACROS[@]}"; do
                set +e
                grep -q "$MACRO" "$FN"
                RET=$?
                set -e
                tap_ok $RET "Macro found in $FN - $MACRO" "$0" $LINENO
                if [[ 0 -ne $RET ]]; then
                        set -A MISSING "${MISSING[@]}" $MACRO
                fi
        done
        # Print the ones missing from this file.
        tap_is "${#MISSING[@]}" 0 "No macros missing from $FN" "$0" $LINENO
        if [[ 0 -ne ${#MISSING[@]} ]]; then
                tap_diag "Macros missing from $FN"
                for MACRO in "${MISSING[@]}"; do
                        tap_diag "   $MACRO"
                done
        fi
done

# vim: ft=sh

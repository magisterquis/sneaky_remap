#!/bin/ksh
#
# api_docs.t
# Make sure API is documented
# By J. Stuart McMurray
# Created 20250809
# Last Modified 20250809

set -euo pipefail

. ./t/shmore.subr

README=README.md

# Files in which we expect to find macros.
set -A FILES sneaky_remap.h sneaky_remap.go

# Find all of the macros which should be in the README
set -A FMACROS $(grep -Eho 'SREM_[A-Z_]+[A-Z]' "${FILES[@]}" | sort -u)
NFMACROS=${#FMACROS[@]}
set -A RMACROS $(grep -Eho 'SREM_[A-Z_]+[A-Z]' "$README" | sort -u)
NRMACROS=${#RMACROS[@]}

# One for the list, one for each file itself, one for each macro in each file.
tap_plan $((4 + $NFMACROS + $NRMACROS))

# Make sure we actually found macros.
tap_cmp_ok \
        $NFMACROS -gt 0 \
        "Found SREM_* macros in: ${FILES[*]}" \
        "$0" $LINENO
tap_cmp_ok \
        $NRMACROS -gt 0 \
        "Found SREM_* macros in: $README" \
        "$0" $LINENO

# Make sure each macro from the source files is somewhere in the README.
set -A MISSING
for MACRO in "${FMACROS[@]}"; do
        set +e
        grep -q "$MACRO" "$README"
        RET=$?
        set -e
        tap_ok $RET "Macro found in $README - $MACRO" "$0" $LINENO
        if [[ 0 -ne $RET ]]; then
                set -A MISSING "${MISSING[@]}" $MACRO
        fi
done

# Print the ones missing from the README.
tap_is "${#MISSING[@]}" 0 "No macros missing from $README" "$0" $LINENO
if [[ 0 -ne ${#MISSING[@]} ]]; then
        tap_diag "Macros missing from $README"
        for MACRO in "${MISSING[@]}"; do
                tap_diag "   $MACRO"
        done
fi

# Make sure each macro in the README is somewhere in one of the files.
set -A MISSING
for MACRO in "${RMACROS[@]}"; do
        set +e
        grep -q "$MACRO" "${FILES[@]}"
        RET=$?
        set -e
        tap_ok $RET \
                "Macro in $README found in sources - $MACRO" \
                "$0" $LINENO
        if [[ 0 -ne $RET ]]; then
                set -A MISSING "${MISSING[@]}" $MACRO
        fi
done

# Print the ones missing from source files.
tap_is "${#MISSING[@]}" 0 "No macros missing from ${FILES[*]}" "$0" $LINENO
if [[ 0 -ne ${#MISSING[@]} ]]; then
        tap_diag "Macros missing from $FN"
        for MACRO in "${MISSING[@]}"; do
                tap_diag "   $MACRO"
        done
fi

# vim: ft=sh

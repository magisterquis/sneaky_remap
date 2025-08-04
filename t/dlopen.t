#!/bin/ksh
#
# dlopen.t
# Make sure we can dlopen ourselves
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250730

set -euo pipefail

. t/test_loader.subr

tap_plan 8

# enable_stderr_ok wraps tap_is to check if enable_stderr has bash whining
# about not getting the right sort of library symbols.
# 
# Arguments:
# $0 - Test script name (not function name)
# $1 - Test name
# $2 - Line number ($LINENO)
enable_stderr_ok() {
        GOT=$(<./enable_stderr)
        WANT='bash: line 2: enable: cannot find ./lib.so_struct in shared object ./lib.so: ./lib.so: undefined symbol: ./lib.so_struct
bash: line 2: enable: ./lib.so: not a shell builtin'
        tap_is "$GOT" "$WANT" "$1" "$0" "$2"
}

# Build and load the library.
test_loader "" $LINENO

# Load with bash without dlopening.  It should go away.
LIB=$LIB bash <<'_eof'
echo -E "$(</proc/$$/maps)" >bash_before
enable "./$LIB" 2>enable_stderr
echo -E "$(</proc/$$/maps)" >bash_after
_eof
GOT=$(grep -ve '\[stack\]$' bash_after)
WANT=$(grep -ve '\[stack\]$' bash_before)
tap_is \
        "$GOT" "$WANT" \
        "Non-SREM_SRS_DLOPEN Library unloaded after enable" \
        "$0" $LINENO
enable_stderr_ok "Non-SREM_SRS_DLOPEN library caused enable to whine" $LINENO

# Make a dlopen(3) version.
rm "$LIB"
export CFLAGS="-DSRSFLAGS=SREM_SRS_DLOPEN"
bmake -f ./common.mk "$LIB"
set +e
[[ -f "$LIB" ]]
RET=$?
set -e
tap_ok $RET "SREM_SRS_DLOPEN library $LIB created" "$0" $LINENO

# Should get a few more mapped files
LIB=$LIB bash <<'_eof'
echo -E "$(</proc/$$/maps)" >bash_before
enable "./$LIB" 2>enable_stderr
echo -E "$(</proc/$$/maps)" >bash_after
_eof
NEW=$(diff bash_before bash_after | grep -Ev '\[stack\]$' | grep -E '^>' ||:)
NNEW=$(($(echo -E "$NEW" | wc -l)))
tap_isnt "$NNEW" 0 "SREM_SRS_DLOPEN left new mapped memory" "$0" $LINENO
function subtest {
        tap_plan "$NNEW"
        N=0
        echo "$NEW" |
        while read; do
                : $((N++))
                tap_like \
                        "$REPLY" \
                        '^> [0-9a-f]+-[0-9a-f]+ [r-][w-][x-]p 0{8} 00:00 0$' \
                        "Line $N has no mapped file" \
                        "$0" $LINENO
        done
}
tap_subtest "New maps after SREM_SRS_DLOPEN" "subtest" "$0" $LINENO
enable_stderr_ok "SREM_SRS_DLOPEN library caused enable to whine" $LINENO

# vim: ft=sh

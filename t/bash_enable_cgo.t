#!/bin/ksh
#
# bash_enable_cgo.t
# Test running self-hiding Go library with a thread, with go get
# By J. Stuart McMurray
# Created 20250730
# Last Modified 20250730

set -euo pipefail

. t/test_loader.subr

tap_plan 5

# Build our library
test_loader "" $LINENO

# Make sure the library works as a background thread in Bash.
set +e
WANT="Go is running"
GOT=$(bash <<_eof
        set -euo pipefail

        # Memory map before we load the library.
        cat </proc/\$\$/maps >"$MAPS_BEFORE"

        # Load the library
        ! enable "./$LIB" 2>&1

        # Wait up to ~2s for the counter file to exist then change. 
        i=0
        LAST=
        CF=counter
        while [[ 20 -gt \$i ]]; do
                if [[ -f "\$CF" ]]; then
                        CUR=\$(<"\$CF")
                        if [[ -n "\$CUR" && "\$CUR" != "\$LAST" ]]; then
                                echo "$WANT"
                                break
                        fi
                        LAST=\$CUR
                fi
                : \$((i++))
                sleep .1
        done
                
        # Memory map after we load the library.
        cat </proc/\$\$/maps >"$MAPS_AFTER"
_eof
)
RET=$?
GOT=$(echo "$GOT" | grep -Ev "^bash: line 7: enable:") # Whiny...
set -e
tap_is  $RET   0      "Bash script with enable exited happily" "$0" $LINENO
tap_is "$GOT" "$WANT" "Correct line proxied through Go"        "$0" $LINENO

# Make sure we didn't sprout any mapped files while running in Bash.
no_new_mapped_files \
        "$MAPS_BEFORE" "$MAPS_AFTER" \
        "No new mapped files after enabling in Bash" \
        $LINENO

# vim: ft=sh

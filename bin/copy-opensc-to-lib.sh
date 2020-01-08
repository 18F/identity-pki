#!/bin/bash
# https://github.com/OpenSC/OpenSC/issues/1008
# Copy opensc library into /usr/local/lib/ so it's on the default ssh-agent
# whitelist.
set -euo pipefail

trap "echo ERROR" EXIT

run() {
    echo >&2 "+ $*"
    "$@"
}

lib="/usr/local/lib/opensc-pkcs11.so"
src="$(run brew list opensc | grep lib/opensc-pkcs11.so)"

# ensure exists
cat "$src" >/dev/null

if [ -L "$lib" ]; then
    echo "$lib is a link"
    run rm -fv "$lib"
fi

if [ -e "$lib" ]; then
    echo "$lib exists"
    if [ -f "$lib" ]; then
        echo "$lib is a regular file"
    fi

    if run diff -q "$src" "$lib"; then
        echo "Files are identical, nothing to do"
        trap - EXIT
        exit
    fi
fi

run cp -avi "$src" "$lib"

trap - EXIT

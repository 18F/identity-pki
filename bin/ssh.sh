#!/bin/bash
set -euo pipefail

run() {
    echo >&2 "+ $*"
    "$@"
}

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") HOST [ENVIRONMENT] [SSH_OPTS]

SSH into HOST in ENVIRONMENT. For hosts other than the jumphost, proxy through
the jumphost.

For example:
    $(basename "$0") idp1-0 dev

    $(basename "$0") chef qa

    Use host.environment:
        $(basename "$0") idp1-0.dev

    Pass options to SSH:
        $(basename "$0") idp1-0 dev -v -l ubuntu

    Pass a remote command:
        $(basename "$0") idp1-0 dev -- somecommand

If your local username differs from the server's username, you can add
something like this to your ~/.ssh/config:

    host *.login.gov
    user myusername
EOM
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

host="$1"

if [ $# -ge 2 ]; then
    environ="$2"
else
    if [[ $host == *.* ]]; then
        environ="$(cut -d. -f2- <<< "$host")"
        host="$(cut -d. -f1 <<< "$host")"
    else
        usage
        exit 1
    fi
fi

opts=()

# handle SSH_OPTS
shift 2

cmd=()
while [ $# -gt 1 ]; do
    if [ "$1" == "--" ]; then
        shift
        cmd=("$@")
        break
    fi
    opts+=("$1")
    shift
done

# Don't bother with hostkeys in nonprod since we don't yet have a good
# management strategy for this. TODO: remove this!
case "$environ" in
    prod)
        ;;
    *)
        opts+=("-o" "StrictHostKeyChecking=no")
        ;;
esac

if [ "$host" != "jumphost" ]; then
    opts+=("-o" "ProxyCommand=ssh ${opts[@]-} jumphost.$environ.login.gov -W $host:22")
fi

if [ "${#cmd[@]}" -gt 0 ]; then
    run ssh "${opts[@]-}" "$host.$environ.login.gov" "${cmd[@]}"
else
    run ssh "${opts[@]-}" "$host.$environ.login.gov"
fi

#!/bin/bash
set -euo pipefail

if [ "$(id -u)" -ne 0 ]; then
    set -x
    exec sudo "$0" "$@"
fi

interval=0.25
case $# in
    0)
        ;;
    1)
        interval="$1"
        ;;
    *)
        echo >&2 "usage: $0 [SLEEP_INTERVAL]"
        ;;
esac

interval=0.25

stream_add_date() {
    while read -r line; do
        date "+%F %T" | tr -d '\n'
        echo -n ": "
        echo "$line"
    done
}

while sleep -- "$interval"; do
    proc="$(fuser /var/lib/dpkg/lock /var/lib/dpkg/lock-frontend /var/lib/apt/lists/lock || true 2>/dev/null)"
    proc="$(sed 's/^ *//' <<< "$proc")" # trim whitespace
    if [ -n "$proc" ]; then
        date "+%F %T"
        # shellcheck disable=SC2086
        ps -fp "$proc"
    fi
done

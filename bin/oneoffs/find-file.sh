#!/bin/bash
set -eu

run() {
  echo >&2 "+ $*"
  "$@"
}

if [ $# -lt 2 ]; then
  cat >&2 <<EOM
usage: $0 FILENAME FILE_MD5

Search / (except for /proc and /sys) for files named FILENAME and files with
md5sum of FILE_MD5.

Exit codes:
  0: not found
  1: error
  2: targets found
EOM
  exit 1
fi

target_filename="$1"
target_md5="$2"
hostname="$(hostname -f)"

if [ "$(id -u)" -ne 0 ]; then
  echo >&2 "this script must be run as root"
  exit 1
fi

logfile="$(mktemp)"


# shellcheck disable=SC2064
trap "rm -f '$logfile'" EXIT

(
set -x
find / \( -path /sys -o -path /proc \) -prune -o -type f -name "$target_filename" -print | tee -a "$logfile"
)

if [ -s "$logfile" ]; then
  echo "$hostname: result TARGET FOUND by filename"
  exit 2
fi

(
set -x
find / \( -path /sys -o -path /proc \) -prune -o -type f -print0 | xargs -0 md5sum | grep "^$target_md5" | tee -a "$logfile"
)

output="$(cat "$logfile")"

if [ -z "$output" ]; then
  echo "$hostname: result clean"
else
  echo "$hostname: result TARGET FOUND by md5sum"
  trap - EXIT
  exit 2
fi

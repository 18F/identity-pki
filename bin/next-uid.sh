#!/usr/bin/env bash

# This script examines the user databags in
# s3://login-gov-secrets-test/kitchen/data_bags/users and emits
# the first unoccupied UID after 2600.

set -euo pipefail

declare -r BASE_UID=2600
declare -r SECRETS_PATH=s3://login-gov-secrets-test/kitchen/data_bags/users

function run() {
  echo "+ $*" >&2
  "$@"
}

# Examine the S3 bucket and emit the numeric UIDs found within it.
function get_used_uids() {
  local -r tmpdir=$(mktemp -d -t databags)
  trap 'rm -rf "$tmpdir"' RETURN EXIT

  aws s3 cp --quiet --recursive "$SECRETS_PATH" "$tmpdir"
  cat "$tmpdir"/*.json 2>/dev/null \
      | awk '/.*"uid": ([0-9]+)/ { print $2 }' \
      | cut -d, -f1
}

# Finds the first unused UID starting from base_uid.
#
# Args:
#   base_uid: the numeric UID we should start looking from
function find_unused_uid() {
  local next_uid=$1
  local -i num_found=0

  for uid in $(get_used_uids | sort -n); do
    (( num_found++ ))
    if [[ $next_uid -lt $uid ]]; then
      break
    fi
    if [[ $next_uid -eq $uid ]]; then
      (( next_uid++ ))
    fi
  done

  if [[ $num_found -eq 0 ]]; then
    echo "No UIDs found in $SECRETS_PATH; assuming this isn't right" >&2
    return 1
  fi

  echo $next_uid
}

find_unused_uid $BASE_UID

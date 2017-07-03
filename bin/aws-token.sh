#!/bin/bash
# This file should be sourced for use.

usage() {
    cat >&2 <<EOM
usage: . $0 [AWS_PROFILE]

This script calls the AWS API to get temporary session tokens from the STS API,
which will be valid for 1 hour by default. These tokens are safer to use with
ssh -A than long-lived credentials because they expire after a short time.

It must be sourced by the current shell in order to export these environment
variables:
    AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

If AWS_PROFILE is provided, it will be used to look up long-term credentials
from ~/.aws/credentials. Otherwise, the aws CLI will look up credentials
through the normal means, by config and by environment variables.

EOM
}

# If we are not sourced, print usage
if [ "$0" = "${BASH_SOURCE[0]}" ]; then
    usage
    exit 1
fi

run() {
    echo >&2 "+ $*"
    "$@"
}

aws_get_session_token() {
    local output
    output="$(run aws sts get-session-token --output text)" || return 1

    AWS_ACCESS_KEY_ID="$(cut -f2 <<< "$output")"
    AWS_SECRET_ACCESS_KEY="$(cut -f4 <<< "$output")"
    AWS_SESSION_TOKEN="$(cut -f5 <<< "$output")"

    echo >&2 "+ export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN"
    export AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN

    echo >&2 "Expiration: $(cut -f3 <<< "$output")"
}

case $# in
    0)
        aws_get_session_token
        ;;
    1)
        echo >&2 "using local AWS_PROFILE=$1"
        if [ -n "${AWS_SESSION_TOKEN-}" ]; then
            unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
        fi
        AWS_PROFILE="$1" aws_get_session_token
        ;;
    *)
        usage
        return 1
        ;;
esac

#!/bin/sh

set -eu

BUCKET=login-gov-secrets-test
USERS_PATH="s3://$BUCKET/kitchen/data_bags/users/"

run() {
    echo >&2 "+ $*"
    "$@"
}

usage() {
    cat >&2 <<EOM
usage: $0 sync-down
usage: $0 upload FILE

Available commands:

  sync-down:
    Download all files from $USERS_PATH to this directory.
    WARNING: may overwrite any files you have in this script's directory '$(dirname "$0")/'

  upload FILE:
    Copy FILE into S3 at $USERS_PATH
EOM
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

case "$1" in
    sync-down)
        cmd_sync_down
        ;;
    upload)
        if [ $# -lt 2 ]; then
            usage
            exit 2
        fi
        cmd_upload_one "$2"
        ;;
    *)
        usage
        exit 1
        ;;
esac

cmd_sync_down() {
    cd "$(dirname "$0")"

    run aws s3 sync "$USERS_PATH" ./
}

cmd_upload_one() {
    cd "$(dirname "$0")"

    filename="$1"

    run aws s3 cp "$filename" "$USERS_PATH"
}


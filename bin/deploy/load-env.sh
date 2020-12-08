#!/bin/bash
#
# Currently, our automation depends on a number of environment variables to
# configure terraform.  See
# https://www.terraform.io/docs/configuration/variables.html#environment-variables.
#
# There are some variables that are the same across each run, but some user
# specific configuration that's mixed in.  This script is an attempt to factor
# out and check for some of that configuration.
#
# Do not source this directly, only source it from another script that depends
# on this environment configuration, because it does some error checking and
# may exit your shell.
# See: https://github.com/18F/identity-devops/pull/252

BASENAME="$(basename "${BASH_SOURCE[0]}")"
DIRNAME="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=/dev/null
. "$DIRNAME/../lib/common.sh"

usage() {
    cat >&2 <<EOM
Usage: $BASENAME ENVIRONMENT_NAME

Load environment files for ENVIRONMENT_NAME, and do some sanity checking to
ensure we have all the necessary variables.

This script loads environment variables from identity-devops-private. It is not
typically called directly, but instead is invoked by \`deploy\`.

NOTE: This script might exit your shell if you source it and don't have all the
right stuff set up. It's a good idea to only source it from another script, or
just to be really sure you've set all the necessary variables.

Set \$ENV_DEBUG=1 to print environment variables once we finish.
Set \$SKIP_GIT_PULL=1 to skip automatic git pull of identity-devops-private.

(Expert mode only) Set \$ID_ENV_FILE to override the normal environment loader
and use a single env file. Not recommended unless you have particular reason to
do so.

EOM
}

if [ $# -ne 1 ]; then
    usage

    # The `return 1 || exit 1` pattern allows us to return non-zero exit codes
    # to the user without exiting their shell if they are sourcing this file.
    return 1 2>/dev/null || exit 1
fi

echo_blue >&2 "$BASENAME $*"

export TF_VAR_env_name="$1"

ID_ENV_FILE="${ID_ENV_FILE-}"
if [ -n "$ID_ENV_FILE" ]; then
    echo_red "Warning: not using normal variables from identity-devops-private"
    echo_red "Loading variables as requested from '$ID_ENV_FILE'"

    # shellcheck source=/dev/null
    . "$ID_ENV_FILE"

    return 0 2>/dev/null || exit 0
fi

# Locate and potentially git clone identity-devops-private
ID_ENV_DIR="$(run "$DIRNAME/get-private-env.sh")"

if [ -z "$ID_ENV_DIR" ]; then
    echo_red "get-private-env.sh failed"
    return 3 >/dev/null || exit 3
fi

if [ "$(wc -l <<< "$ID_ENV_DIR")" -ne 1 ]; then
    echo_red "get-private-env.sh bug: file path shouldn't be multiple lines"
    echo_red "Path: '$ID_ENV_DIR'"
    return 3 >/dev/null || exit 3
fi

env_specific_path="$ID_ENV_DIR/$TF_VAR_env_name.sh"
if [ -e "$env_specific_path" ]; then
    log "Sourcing env-specific private env vars."
    log "Path: '$env_specific_path'"

    # shellcheck source=/dev/null
    . "$env_specific_path"
else
    log "No env-specific vars file found: ($TF_VAR_env_name.sh)"
    echo_red >&2 "Unknown environment: '$TF_VAR_env_name'"
    echo_red >&2 "Please create env file $TF_VAR_env_name.sh in $ID_ENV_DIR"
    return 4 2>/dev/null || exit 4
fi

if [ -n "${ENV_DEBUG-}" ]; then
    env
fi

if env | grep ^TV_VAR_; then
    echo_red "Found variables named TV_VAR_, but you probably meant TF_VAR_!"
    echo_red "$(env | grep ^TV_VAR_)"
fi

# shellcheck disable=SC2163,SC2086
export ${!TF_VAR_*}

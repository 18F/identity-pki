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
. "$DIRNAME/lib/common.sh"

usage() {
    cat >&2 <<EOM
Usage: $BASENAME ENVIRONMENT_NAME [USERNAME] [ENV_FILE]

Load environment files for ENVIRONMENT_NAME, and do some sanity checking to
ensure we have all the necessary variables.

USERNAME: Required if \$GSA_USERNAME is not set.
ENV_FILE: Defaults to ../env/env.sh

NOTE: This script will exit your shell if you source it and don't have all the
right stuff set up. It's a good idea to only source it from another script, or
just to be really sure you've set all the necessary variables.

Set \$ENV_DEBUG=1 to print environment variables once we finish.
EOM
}

# Check for empty even with "set -u" on http://stackoverflow.com/a/16753536
if [ -z "${GSA_FULLNAME:=}" ] || [ -z "${GSA_EMAIL:=}" ]; then
    echo >&2 "Must set GSA_FULLNAME and GSA_EMAIL in your environment"
    echo >&2 "GSA_FULLNAME is \"Firstname Lastname\" separated by a space"
    return 1 2>/dev/null || exit 1
fi

if [ $# -lt 1 ] || [ $# -gt 3 ]; then
    usage

    # The `return 1 || exit 1` pattern allows us to return non-zero exit codes
    # to the user without exiting their shell if they are sourcing this file.
    return 1 2>/dev/null || exit 1
fi

echo_blue >&2 "$BASENAME $*"

export TF_VAR_env_name="$1"

if [ -z "${GSA_USERNAME-}" ] && [ $# -lt 2 ]; then
    usage
    echo_red >&2 "$BASENAME: error: \$GSA_USERNAME must be set or USERNAME provided as arg"
    return 2 2>/dev/null || exit 2
fi

GSA_USERNAME="${GSA_USERNAME-$2}"

if [ $# -ge 3 ]; then
    ENV_FILE="$3"
else
    ENV_FILE="$DIRNAME/../env/env.sh"
fi

log "Sourcing $ENV_FILE"
# shellcheck source=/dev/null
. "$ENV_FILE"

private_env_location="$(run "$DIRNAME/get-private-env.sh" "$TF_VAR_env_name")"

if [ "$(wc -l <<< "$private_env_location")" -ne 1 ]; then
    echo_red "get-private-env.sh bug: file path shouldn't be multiple lines"
    echo_red "Path: $private_env_location"
fi

log "Sourcing private env-specific vars."
log "Path: '$private_env_location'"
# shellcheck source=/dev/null
. "$private_env_location"

if [ -n "${ENV_DEBUG-}" ]; then
    env
fi

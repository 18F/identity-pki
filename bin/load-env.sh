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

# Increment this to make breaking changes in the environment config. The
# load-env.sh script will bail out if the environment does not set a variable
# $ID_ENV_COMPAT_VERSION >= this value, which provides a way to ensure that new
# scripts get run with a new enough environment config.
ENFORCED_ENV_COMPAT_VERSION=3

BASENAME="$(basename "${BASH_SOURCE[0]}")"
DIRNAME="$(dirname "${BASH_SOURCE[0]}")"

# shellcheck source=/dev/null
. "$DIRNAME/lib/common.sh"

usage() {
    cat >&2 <<EOM
Usage: $BASENAME ENVIRONMENT_NAME [USERNAME] [ENV_FILE]

Load environment files for ENVIRONMENT_NAME, and do some sanity checking to
ensure we have all the necessary variables.

This script loads environment variables from identity-devops-private.

USERNAME: Required if \$GSA_USERNAME is not set.
ENV_FILE: Override the normal environment loader and use a single env file. Not
          recommended unless you have particular reason to do so.

NOTE: This script might exit your shell if you source it and don't have all the
right stuff set up. It's a good idea to only source it from another script, or
just to be really sure you've set all the necessary variables.

Set \$ENV_DEBUG=1 to print environment variables once we finish.
Set \$SKIP_GIT_PULL=1 to skip automatic git pull of identity-devops-private.
EOM
}

# Make sure the loaded environment is new enough.
enforce_environment_compat_version() {
    if [ -z "${ID_ENV_COMPAT_VERSION-}" ]; then
        echo_red "$BASENAME: error: \$ID_ENV_COMPAT_VERSION not set by env"
        echo_red "This ought to be set in identity-devops-private/env/*.sh"
        echo_red "Maybe check if that repo is up-to-date?"
        return 1
    fi

    if [ "$ID_ENV_COMPAT_VERSION" -lt "$ENFORCED_ENV_COMPAT_VERSION" ]; then
        echo_red "$BASENAME: error: \$ID_ENV_COMPAT_VERSION set by env is old"
        echo_red "This means your identity-devops-private clone is outdated."
        echo_red "Try updating that repo to latest master?"
        echo_red "\$ID_ENV_COMPAT_VERSION: $ID_ENV_COMPAT_VERSION"
        echo_red "\$ENFORCED_ENV_COMPAT_VERSION: $ENFORCED_ENV_COMPAT_VERSION"
        return 1
    fi
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
    echo_red "Warning: not using normal variables from identity-devops-private"
    echo_red "Loading variables as requested from '$ENV_FILE'"

    # shellcheck source=/dev/null
    . "$ENV_FILE"

    enforce_environment_compat_version || return 4 2>/dev/null || exit 4

    return 0 2>/dev/null || exit 0
fi

# Check if env/env.sh exists, and if so inform the user about the migration to
# private, checked-in environment variable configs.
if [ -e "$DIRNAME/../env/env.sh" ]; then
    echo_yellow >&2 "Warning: $BASENAME found untracked env file at env/env.sh"
    echo_yellow >&2 "
This env.sh will not be used due to
  https://github.com/18F/identity-devops/pull/350
We're migrating our workflow so that environment variables are always checked
in to version control in identity-devops-private. Please remove the local
untracked env.sh after double checking that there is no data in it that is
missing from identity-devops-private/env/base.sh.

(The base.sh was created as a copy of env/env.sh.example in this repo, so
there shouldn't be any changes unless you've made changes locally.)
"
    if prompt_yn "Would you like to move env.sh to env.sh.backup?"; then
        run mv -vn "$DIRNAME/../env/env.sh" "$DIRNAME/../env/env.sh.backup"
    else
        echo >&2 "OK, continuing on"
    fi
fi

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
    echo_yellow >&2 "Using default variables from default.sh"
    echo_yellow >&2 "You may wish to create $TF_VAR_env_name.sh in $ID_ENV_DIR"

    log "Sourcing default private env vars."
    log "Path: '$ID_ENV_DIR/default.sh'"
    # shellcheck source=/dev/null
    . "$ID_ENV_DIR/default.sh"
fi

enforce_environment_compat_version || return 4 2>/dev/null || exit 4

if [ -n "${ENV_DEBUG-}" ]; then
    env
fi

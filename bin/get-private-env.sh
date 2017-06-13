#!/usr/bin/env bash

set -eu

# Try really hard not to let anything accidentally write to stdout.
# Point stdout at stderr and open FD 3 to point to the original stdout.
# Use echo >&3 to write to stdout hereafter.
exec 3>&1 1>&2

BASENAME="$(basename "$0")"

if [ $# -ne 0 ]; then
    cat >&2 <<EOM
usage: $BASENAME

Print the directory containing environment-specific variables. Clone the
private repo containing these variables if it doesn't exist. Within this
directory, the caller should source '\$ENV.sh' if it exists, or potentially
fall back to 'default.sh' if it doesn't.

LOCATION OF PRIVATE REPO:

This script expects to find the private configuration checked out in a separate
repository located (from the root of this repo) at ../{repo-name}-private/.
Customize this path with \$IDENTITY_DEVOPS_PRIVATE_PATH.

If the checkout does not exist, it will offer to clone the repo for you. Set
environment variable \$IDENTITY_DEVOPS_PRIVATE_URL to configure the URL for
identity-devops-private, otherwise 'git remote get-url origin' will be used
with an appended '-private'.

Set SKIP_GIT_CLONE=1 in your environment to skip the prompt for the git
clone.
Set SKIP_GIT_PULL=1 in your environment to skip the automatic git pull.
EOM
    exit 1
fi

SKIP_GIT_CLONE="${SKIP_GIT_CLONE-}"
SKIP_GIT_PULL="${SKIP_GIT_PULL-}"

# shellcheck source=/dev/null
. "$(dirname "$0")/lib/common.sh"

# Determine the likely URL for identity-devops-private based on the "origin"
# git remote of the current repository (just by appending -private).
# Expects that the CWD is under the current git checkout.
get_private_url_from_origin() {
    local origin_url private_url

    origin_url="$(run git remote get-url origin)"

    # splice off trailing .git if present
    origin_url="${origin_url%.git}"

    # splice off trailing / if present
    origin_url="${origin_url%/}"

    private_url="$origin_url-private"

    echo >&2 "Inferred default identity-devops-private URL: $private_url"
    echo "$private_url"
}

get_private_path() {
    local toplevel basename

    # We assume git rev-parse --show-toplevel returns an absolute path with no
    # trailing slash.
    toplevel="$(run git rev-parse --show-toplevel)"
    basename="$(basename "$toplevel")"

    # ../{basename}-private
    echo "$(dirname "$toplevel")/$basename-private"
}

# usage: clone_private_repo PARENT_DIR
#
# Git clone the identity-devops-private repo under PARENT_DIR locally.
clone_private_repo() {
    local parent_dir clone_url
    parent_dir="$1"

    clone_url="${IDENTITY_DEVOPS_PRIVATE_URL-$(get_private_url_from_origin)}"

    pushd "$parent_dir"

    run git clone "$clone_url"

    popd
}

check_maybe_clone_private_repo() {
    local path

    path="$1"

    if [ ! -d "$path" ]; then
        echo >&2 "warning: Private repo is not checked out at $path"

        if [ -n "$SKIP_GIT_CLONE" ]; then
            echo >&2 "SKIP_GIT_CLONE is set, aborting."
            return 1
        fi

        if prompt_yn "Do you want to git clone the private repo?"; then
            echo >&2 "OK, cloning..."
            clone_private_repo "$(dirname "$path")"

            if [ -d "$path" ]; then
                echo >&2 "Clone done"
            else
                echo >&2 "Something went wrong cloning."
                return 2
            fi
        else
            echo >&2 "OK, aborting."
            return 1
        fi
    fi
}

git_pull() {
    if [ -n "$SKIP_GIT_PULL" ]; then
        echo >&2 "SKIP_GIT_PULL is set, skipping git pull of private repo"
        return
    fi

    local dir basename
    dir="$1"

    basename="$(basename "$dir")"

    echo >&2 "Updating $basename, set env var SKIP_GIT_PULL=1 to skip"

    local cur_branch
    cur_branch="$(run git -C "$dir" symbolic-ref --short HEAD)"
    if [ "$cur_branch" != "master" ]; then
        echo_yellow >&2 \
            "Warning: current $basename branch is $cur_branch, not master"
    fi

    if run git -C "$dir" pull --ff-only --no-rebase; then
        return
    else
        echo_red >&2 "Error: git pull failed"
    fi
}

echo_blue >&2 "Looking for env-specific variables"

private_path="${IDENTITY_DEVOPS_PRIVATE_PATH-$(get_private_path)}"

check_maybe_clone_private_repo "$private_path"

git_pull "$private_path"

if [ ! -e "$private_path/env/default.sh" ]; then
    echo >&2 "Somehow $private_path/env/default.sh is missing!"
    exit 3
fi

found="$private_path/env"
log "Found env variables at $found/"

echo >&3 "$found"

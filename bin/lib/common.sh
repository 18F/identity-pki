#!/bin/bash

# Common shell functions.
# Having a library like this is a surefire sign that you are using too much
# shell and should switch to something like Ruby. But our scripts currently
# pass around a ton of stuff with shell environment variables, so this will
# have to do for the time being.

run() {
    echo >&2 "+ $*"
    "$@"
}

# Prompt the user for a yes/no response.
# Exit codes:
#   0: user entered yes
#   1: user entered no
#   2: STDIN is not a TTY
#
prompt_yn() {
    local prompt ans
    if [ $# -ge 1 ]; then
        prompt="$1"
    else
        prompt="Continue?"
    fi

    if [ ! -t 0 ]; then
        echo >&2 "$prompt [y/n]"
        echo >&2 "prompt_yn: error: stdin is not a TTY!"
        return 2
    fi

    while true; do
        read -r -p "$prompt [y/n] " ans
        case "$ans" in
            Y|y|yes|YES|Yes)
                return
                ;;
            N|n|no|NO|No)
                return 1
                ;;
        esac
    done
}

echo_color() {
    local color code
    color="$1"
    shift

    case "$color" in
        red)    code=31 ;;
        green)  code=32 ;;
        yellow) code=33 ;;
        blue)   code=34 ;;
        purple) code=35 ;;
        cyan)   code=36 ;;
        *)
            echo >&2 "echo_color: unknown color $color"
            return 1
            ;;
    esac

    if [ -t 1 ]; then
        echo -ne "\033[1;${code}m"
    fi

    echo -n "$*"

    if [ -t 1 ]; then
        echo -ne "\033[m"
    fi

    echo
}

echo_blue() {
    echo_color blue "$@"
}
echo_red() {
    echo_color red "$@"
}
echo_yellow() {
    echo_color yellow "$@"
}

log() {
    # print our caller if possible as the basename
    if [ "${#BASH_SOURCE[@]}" -ge 2 ]; then
        local basename
        basename="${BASH_SOURCE[1]}"
        if [[ $basename = */* ]]; then
            basename="$(basename "$basename")"
        fi
        echo >&2 -n "$basename: "
    fi
    echo >&2 "$*"
}

get_terraform_version() {
    local ret

    # checkpoint is the hashicorp thing that phones home to check versions
    CHECKPOINT_DISABLE=1 run terraform --version | head -1 | cut -d' ' -f2 \
        && ret=$? || ret=$?

    # Transform SIGPIPE into exit status 0.
    # When set -o pipefail is set, we expect head -1 to cause
    # terraform --version to receive a SIGPIPE.
    if [ "$ret" -eq 141 ]; then
        return 0
    fi

    return "$ret"
}

# usage: check_terraform_version SUPPORTED_VERSION...
#
# e.g. check_terraform_version v0.8.* v0.9.*
#
# Check whether the current version of terraform (as reported by terraform
# --version) is in the allowed list passed as arguments. Return 0 if so,
# otherwise return 1.
check_terraform_version() {
    current_tf_version="$(get_terraform_version)"

    if [ $# -eq 0 ]; then
        echo_red >&2 \
            "error: no supported versions passed to check_terraform_version"
        return 2
    fi

    for version in "$@"; do
        # version is expected to be a pattern
        # shellcheck disable=SC2053
        if [[ $current_tf_version == $version ]]; then
            echo "Terraform version $current_tf_version is supported"
            return
        fi
    done

    echo_red >&2 "Terraform version $current_tf_version is not supported"
    echo_red >&2 "Expected versions: $*"

    echo >&2 "Tip: you can use \`brew switch terraform VERSION\` to switch to"
    echo >&2 "a target installed version of terraform with homebrew."

    return 1
}

# Similar to Ruby's Array#join
# usage: join_by DELIMITER ELEM...
join_by() {
    local delimiter="$1"
    shift
    if [ $# -eq 0 ]; then
        echo
        return
    fi
    # print first elem with no delimiter
    echo -n "$1"
    shift

    for elem in "$@"; do
        echo -n "$delimiter$elem"
    done

    echo
}

# Output shell array as a terraform-compatible string
# (1 2 3) => '["1", "2", "3"]'
array_to_string() {
    echo "[\"$(join_by '", "' "$@")\"]"
}

#!/bin/bash
# Common shell functions.

# echo full command before executing, then do it anyway
run() {
    echo >&2 "+ $*"
    "$@"
}

# echo error message in red, echo usage(), and exit
raise() {
  echo_red "$*" >&2
  usage
  exit 1
}

# Easier-to-read way to define variable using a heredoc.
# Yoinked from https://stackoverflow.com/a/8088167
define(){
    o=
    while IFS="\n" read -r a; do
        o="$o$a"'
'
    done
    eval "$1=\$o"
}

# verify that script is running from identity-devops repo
verify_root_repo() {
    GIT_DIR=$(git rev-parse --show-toplevel)
    if [ "$(echo ${GIT_DIR} | awk -F/ '{print $NF}')" != 'identity-devops' ]
    then
        raise "Must be run from the identity-devops repo"
    fi
}

# if $ARG is empty, set to val of $ENV_VAR; raise if $ENV_VAR is also empty
arg_or_env_var () {
  ARG=${1}
  ENV_VAR=${2}
  if [[ -z $(eval echo \$${ARG}) ]] ; then
    if [[ -z $(eval echo \$${ENV_VAR}) ]] ; then
      raise "Argument ${ARG} not received and ${ENV_VAR} env var not set"
    else
      eval ${ARG}=$(eval echo \$${ENV_VAR})
    fi
  fi
}

# verify existence of IAM user
verify_iam_user () {
    local WHO_AM_I=${1}
    local IAM_USERS_FILE="terraform-master/module/iam_users.tf"
    local MASTER_ACCOUNT_ID=340731855345
    
    echo_blue "Verifying IAM user ${WHO_AM_I}... "
    if [[ ! $(grep -E "\= \"${WHO_AM_I}\"" "${GIT_DIR}/${IAM_USERS_FILE}") ]] ; then
      raise "User '${WHO_AM_I}' not found in ${IAM_USERS_FILE}"
    fi
    
    if [[ $(aws sts get-caller-identity | jq -r '.Account') != "${MASTER_ACCOUNT_ID}" ]] ; then
      raise "This script must be run with a login-master AWS profile"
    fi
    if [[ ! $(aws iam list-users | grep "user/${WHO_AM_I}") ]] ; then
      raise "User '${WHO_AM_I}' not in list of IAM users in login-master"
    fi
}

# set a variable AND print its declaration to the console
run_var() {
  VAR=${1}
  shift
  if [[ $USE_RUN -gt 0 ]] ; then
    if [ -t 1 ]; then
      echo -ne "\\033[1;36m"
    fi

    echo -e >&2 "+ $VAR=\$($*)"

    if [ -t 1 ]; then
      echo -ne '\033[m'
    fi
  fi
  eval $VAR="\"$($@)\""
}

# Prompt the user for a yes/no response.
# Exit codes:
#   0: user entered yes
#   2: STDIN is not a TTY
#   10: user entered no
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
                return 10
                ;;
        esac
    done
}

# usage: backup_if_exists FILE/DIR MODE
#
# If FILE/DIR exists, prompt to back it up.
# MODE can be --overwrite or --abort. This is used to hint the user for what
# will happen upon a "no" answer.
#
# Upon yes, move it to a timestamped backup name.
# Upon no, return 1 if --abort is given, 0 if --abort is given.
#
backup_if_exists() {
    local target backup_name overwrite
    target="$1"
    mode="$2"

    case "$mode" in
        --overwrite)
            overwrite=1
            prompt="Would you like to back it up? Y=backup N=overwrite"
            ;;
        --abort)
            overwrite=
            prompt="Would you like to back it up? Y=backup N=abort"
            ;;
        *)
            echo_red >&2 "Unexpected backup mode $mode"
            return 2
            ;;
    esac

    if [ -e "$target" ]; then
        echo_yellow >&2 "warning: '$target' already exists"

        prompt_yn "$prompt" && ret=$? || ret=$?

        case "$ret" in
            0)
                backup_name="$target.backup~$(date "+%F.%H-%M-%S")"
                run mv -iv "$target" "$backup_name"
                ;;
            10)
                if [ -n "$overwrite" ]; then
                    echo_yellow >&2 "OK, not backing up"
                    return
                else
                    echo_yellow >&2 "OK, returning error $ret"
                    return "$ret"
                fi
                ;;
            *)
                echo_red >&2 "Unexpected return value $ret from prompt_yn"
                return "$ret"
                ;;
        esac
    fi
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
        echo -ne "\\033[1;${code}m"
    fi

    echo -n "$*"

    if [ -t 1 ]; then
        echo -ne '\033[m'
    fi

    echo
}

echo_blue() {
    echo_color blue "$@"
}
echo_green() {
    echo_color green "$@"
}
echo_red() {
    echo_color red "$@"
}
echo_yellow() {
    echo_color yellow "$@"
}
echo_cyan() {
    echo_color cyan "$@"
}
echo_purple() {
    echo_color purple "$@"
}


# Print underscores as wide as the terminal screen
echo_color_horizontal_rule() {
    declare -i width # local integer
    width="${COLUMNS-80}"

    local color

    case $# in
        0) color=blue ;;
        1) color="$1" ;;
        *)
            echo >&2 "usage: echo_color_horizontal_rule [COLOR]"
            return 1
            ;;
    esac

    echo_color "$color" "$(printf "%0.s_" $(seq 1 "$width"))"
}

log() {
    local color=
    if [ "${1-}" = "--blue" ]; then
        color=34
        shift
    fi

    # print our caller if possible as the basename
    if [ "${#BASH_SOURCE[@]}" -ge 2 ]; then
        local basename
        basename="${BASH_SOURCE[1]}"
        if [[ $basename = */* ]]; then
            basename="$(basename "$basename")"
        fi
        if [ -n "$color" ] && [ -t 2 ]; then
            echo >&2 -ne "\\033[1;${color}m"
        fi
        echo >&2 -n "$basename: "
    fi

    echo >&2 -n "$*"

    if [ -n "$color" ] && [ -t 2 ]; then
        echo >&2 -ne '\033[m'
    fi

    echo >&2
}

get_terraform_version() {
    local output

    # checkpoint is the hashicorp thing that phones home to check versions
    output="$(CHECKPOINT_DISABLE=1 run terraform --version)" || return $?

    # we do this in two phases to avoid sending SIGPIPE to terraform, which
    # would cause it to exit with status 141
    echo "$output" | head -1 | cut -d' ' -f2
}

assert_file_not_exists() {
    if [ -e "$1" ]; then
        echo_red >&2 "error: \`$1' already exists!"
        return 1
    fi
}

assert_file_exists() {
    if [ ! -e "$1" ]; then
        echo_red >&2 "error: \`$1' does not exist!"
        return 1
    fi
}

# Upstream references for the releases:
#   - https://releases.hashicorp.com/terraform/
#
KNOWN_TF_VERSIONS=(
  "v0.10.8"
  "v0.11.14"
  "v0.12.19"
  "v0.12.23"
)

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

    echo >&2 "Try using \`bin/terraform-switch.sh\` to install / switch"
    echo >&2 "to a target installed version of terraform with homebrew."

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


# Usage: verify_repo_root_unchanged REPO_ROOT_BEFORE_CD BASENAME
#
# Double check that the repo root has not changed after executing a cd. This is
# useful in case you are running a script like tf-deploy or diff-deploy on your
# PATH, since the script will cd to the script's own parent directory..
#
# If your prior cwd repo root was not the same as the new repo root, this means
# that you are probably executing a different script from the one you expected.
# Prompt to confirm, since this is probably not what the user intended.
#
verify_repo_root_unchanged() {
    local repo_root_before_cd repo_root_after_cd BASENAME
    repo_root_before_cd="$1"
    BASENAME="$2"

    repo_root_after_cd="$(git rev-parse --show-toplevel)"
    if [ -n "$repo_root_before_cd" ] \
        && [ -e "$repo_root_before_cd/bin/$BASENAME" ] \
        && [ "$repo_root_before_cd" != "$repo_root_after_cd" ]
    then
        echo_yellow >&2 "WARNING: your cwd is in a different directory than $BASENAME.
Are you sure you didn't mean to run ./bin/$BASENAME instead?
Repo root from your cwd:   $repo_root_before_cd
Repo root for $BASENAME: $repo_root_after_cd"
        prompt_yn
    fi
}

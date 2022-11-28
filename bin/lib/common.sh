#!/bin/bash
# Common shell functions.

ave() {
  local ECHO_RUN=true
  if [[ ${1} == '-r' ]] ; then
    ECHO_RUN=false
    shift 1
  fi
  local run_me=("$@")
  if [[ ${ECHO_RUN} == true ]] ; then
    if [ -t 1 ]; then
      echo -ne "\\033[1;36m"
    fi

    echo >&2 "+ ${run_me[@]}"

    if [ -t 1 ]; then
      echo -ne '\033[m'
    fi
  fi
  if [[ ! -z ${AWS_PROFILE:-} ]] ; then
    "${run_me[@]}"
  elif [[ ! -z ${AWS_VAULT:-} ]] && [[ ${SHLVL} -gt 1 ]] ; then
    "${run_me[@]}"
  else
    aws-vault exec ${AV_PROFILE} -- "${run_me[@]}"
  fi
}

# echo full command before executing, then do it anyway
run() {
  run_me=("$@")
    if [ -t 1 ]; then
      echo -ne "\\033[1;36m"
    fi

    echo >&2 "+ ${run_me[@]}"

    if [ -t 1 ]; then
      echo -ne '\033[m'
    fi
  "${run_me[@]}"
}

# echo error message in red, echo usage(), and exit
raise() {
  echo_red "$*" >&2
  usage
  exit 1
}

# Easier-to-read way to define variable using a heredoc.
# Yoinked from https://stackoverflow.com/a/8088167
define() {
  read -r -d '' ${1} || true
}

# parse space/tab-separated column output and space with pipe marks
mdout() {
  echo -e "|$@|" | column -t | tr -s ' ' '|' |
  sed 's/ *| */@| /g' | column -s '@' -t | sed 's/ |/|/g' 
}

# get top profile for ID_ACCT out of aws/config
# Provide ROLE for specific 'role/ROLE' profile
get_iam() {
  local ID_TOP=${1}
  local ID_ACCT=${2}
  local ID_ROLE=${3:-}

  verify_root_repo
  [[ ${ID_TOP} == "app" ]] && ID_TOP="all"
  ACCT_NUM=$(grep 'allowed_account_ids' \
    "${GIT_DIR}/terraform/${ID_TOP}/${ID_ACCT}/main.tf" |
    awk -F'"' '{print $2}')
  if [[ -z ${ID_ROLE} ]] ; then
    AV_PROFILE=$(awk '{a[i++]=$0} END {for (j=i-1; j>=0;) print a[j--] }' \
                 ~/.aws/config |
                 awk -v account="$ACCT_NUM" -v RS= '$0 ~ account' |
                 tail -n 1 | sed -E 's/\[profile (.*)\]/\1/')
  else
    local CONFIG_LINE=$(tail -r ~/.aws/config |
      grep -n "$ACCT_NUM.*$ID_ROLE" | awk -F: '{print $1}') || true
    if [[ ! -z "${CONFIG_LINE}" ]] ; then
        AV_PROFILE=$(tail -r ~/.aws/config | tail -n +${CONFIG_LINE} |
                     grep -m 1 '\[profile' |
                     sed -E 's/\[profile ([a-z-]+)\]/\1/')
    else
      echo
      echo_red "Role ARN not found in ~/.aws/config:"
      echo_yellow "arn:aws:iam::${ACCT_NUM}:role/${ID_ROLE}"
      raise "Verify role, profile, and ARN, and try again!"
    fi
  fi
}

verify_profile () {
  AV_ROLE="${1}"
  if [[ ! $(grep "profile ${AV_ROLE}" ~/.aws/config) ]] ; then
    echo_red "Profile ${AV_ROLE} not found in ~/.aws/config;"
    raise "verify the name and try again!"
  fi
}

# set LOGIN_IAM_PROFILE env var and prompt to add export line to .rc
set_iam_profile () {
  local SET_PROFILE
  while [[ -z "${LOGIN_IAM_PROFILE-}" ]] ; do
    echo_yellow "LOGIN_IAM_PROFILE not set in shell environment variables."
    while [[ -z "${SET_PROFILE}" ]] ; do
      read -r -p "Please specify (i.e. ACCOUNT-LOGIN_IAM_PROFILE): " SET_PROFILE
    done
    run export LOGIN_IAM_PROFILE=${SET_PROFILE}
    echo "Add this line to your .rc file of choice to avoid having to set this in the future:"
    echo -e "\nexport LOGIN_IAM_PROFILE=${SET_PROFILE}\n"
  done
}

# verify that script is running from identity-devops repo
verify_root_repo() {
  GIT_DIR=$(git rev-parse --show-toplevel)
  GIT_DIR_SHORT=$(echo ${GIT_DIR} | awk -F/ '{print $NF}')
  if [[ "${GIT_DIR_SHORT}" != 'identity-devops' ]] ; then
    raise "Must be run from the identity-devops repo"
  fi
}

# send a notification in Slack, pulling appropriate key(s) from bucket to do so
slack_notify() {
  local AWS_ACCT_NUM TF_ENV AWS_REGION COLOR SLACK_USER SLACK_EMOJI PRE_TEXT TEXT KEYS

  while getopts n:t:r:c:u:e:p:m:y: opt
  do
    case "${opt}" in
      n) AWS_ACCT_NUM="${OPTARG}" ;;
      t) TF_ENV="${OPTARG}"       ;;
      r) AWS_REGION="${OPTARG}"   ;;
      c) COLOR="${OPTARG}"        ;;
      u) SLACK_USER="${OPTARG}"   ;;
      e) SLACK_EMOJI="${OPTARG}"  ;;
      p) PRE_TEXT="${OPTARG}"     ;;
      m) TEXT="${OPTARG}"         ;;
      y) TF_TYPE="${OPTARG}"      ;;
    esac
  done

  local BUCKET="s3://login-gov.secrets.${AWS_ACCT_NUM}-${AWS_REGION}"
  if [[ ${TF_TYPE} == 0 ]] ; then
    BUCKET="${BUCKET}/${TF_ENV}"
  fi

  if ! SLACK_CHANNEL=$(aws s3 cp "${BUCKET}/tfslackchannel" - 2>/dev/null) ; then
    if [[ ${TF_TYPE} == 0 ]] ; then
      BUCKET="s3://login-gov.secrets.${AWS_ACCT_NUM}-${AWS_REGION}"
      SLACK_CHANNEL=$(aws s3 cp "${BUCKET}/tfslackchannel" -) || ((KEYS++))
    else
      SLACK_CHANNEL=$(aws s3 cp "${BUCKET}/slackchannel" -) || ((KEYS++))
    fi
  fi
  SLACK_WEBHOOK=$(aws ssm get-parameter --name '/account/slack/webhook/url' --output text --with-decryption --query 'Parameter.Value') || ((KEYS++))
  if [[ "${KEYS}" -gt 0 ]]; then
    echo 'Slack channel/webhook missing from SSM parameter'
    return 1
  fi

  define PAYLOAD_JSON <<EOM
{
  "channel": "${SLACK_CHANNEL}",
  "username": "${SLACK_USER}",
  "icon_emoji": "${SLACK_EMOJI}",
  "attachments": [
  {
    "mrkdwn_in": ["text"],
    "pretext": "${PRE_TEXT}",
    "color": "${COLOR}",
    "text": "${TEXT}"
  }
  ]
}
EOM
  PAYLOAD=$(printf '%s' "${PAYLOAD_JSON}" | jq -c .)
  curl -X POST "${SLACK_WEBHOOK}" --data-urlencode payload="${PAYLOAD}"
  echo -e "\n\n${PRE_TEXT}\n${TEXT}\n" | tr -d "\`" | sed -E "s/\\n/\n/"
}

# verify existence of IAM user in AWS
verify_iam_user() {
  local WHO_AM_I=${1}
  local MASTER_ACCT=340731855345
  local ENV_USER=${AWS_IAM_USER-}

  local IAM_USER_DATA=$(aws iam get-user 2>/dev/null)
  FOUND_USER=$(echo ${IAM_USER_DATA} | jq -r '.[].UserName')
  EC2_USERNAME=$(echo ${IAM_USER_DATA} | jq -r '.[].Tags[]|
    select(.Key == "ec2_username").Value' 2>/dev/null || true)
  
  if [[ -z "${WHO_AM_I}" ]] ; then
    if [[ -z "${ENV_USER}" ]] ; then
      if [[ -z "${FOUND_USER}" ]] ; then
        echo_red "Could not detect current IAM user; also:"
        echo_red "neither IAM_USER, nor env var AWS_IAM_USER, is set;"
        raise "must set either to run with AssumedRole"
      else
        echo_yellow "AWS_IAM_USER not set in env."
        echo_yellow "Using ${FOUND_USER} as IAM_USER."
        WHO_AM_I="${FOUND_USER}"
      fi
    else
      WHO_AM_I="${AWS_IAM_USER}"
    fi
  fi

  verify_iam_user_yaml "${WHO_AM_I}"

  if [[ $(aws sts get-caller-identity | jq -r '.Account') != "${MASTER_ACCT}" ]] ; then
    raise "This script must be run with a login-master AWS profile"
  fi

  if [[ ! $(aws iam list-users | grep "user/${WHO_AM_I}") ]] ; then
    raise "User '${WHO_AM_I}' not in list of IAM users in login-master"
  fi

  echo_cyan "IAM user '${WHO_AM_I}' verified."
  [[ -z ${EC2_USERNAME} ]] || echo_cyan "EC2 username '${EC2_USERNAME}' verified."
  VERIFIED_USER=${WHO_AM_I}
}

# verify IAM user in users.yaml
verify_iam_user_yaml() {
  local USERS_FILE="terraform/master/global/users.yaml"
  if [[ ! $(grep -E "^  ${1}:" "${GIT_DIR}/${USERS_FILE}") ]] ; then
    raise "User '${1}' not found in ${USERS_FILE}"
  fi
}

# set a variable AND print its declaration to the console
run_var() {
  VAR=${1}
  shift
  if [ -t 1 ]; then
    echo -ne "\\033[1;36m"
  fi

  echo -e >&2 "+ $VAR=\$($*)"

  if [ -t 1 ]; then
    echo -ne '\033[m'
  fi
  T=$($@)
  # Set variable value by reference to avoid ; shenanigans
  eval "${VAR}=\"\${T}\""
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
    red)  code=31 ;;
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
  "v1.3.5"
  "v1.2.4"
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

  tf_style="${1}"
  shift 1

  for version in "$@"; do
    # version is expected to be a pattern
    # shellcheck disable=SC2053
    if [[ $current_tf_version == $version ]]; then
      echo "Terraform version $current_tf_version is supported (via $tf_style var)"
      return
    fi
  done

  echo_red >&2 "Terraform version $current_tf_version is not supported"
  echo_red >&2 "Expected versions: $* (via $tf_style var)"

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

## strip off aws-vault exec stuff if running a long AWS_VAULT session ##
run_av() {
  run_me_av=("$@")
  if [[ $(env | grep 'AWS_VAULT=') ]] ; then
    run "${run_me_av[@]}"
  else
    run aws-vault exec ${AV_PROFILE} -- "${run_me_av[@]}"
  fi
}

#### get current working branch; copied from oh-my-zsh/lib/git.zsh ####
git_current_branch() {
  local REF
  REF=$(git symbolic-ref --quiet HEAD 2>/dev/null)
  local RET=$?
  if [[ $RET != 0 ]]; then
  [[ $RET == 128 ]] && return  # no git repo.
  REF=$(git rev-parse --short HEAD 2>/dev/null) || return
  fi
  echo ${REF#refs/heads/}
}

#### use ~/.login-revs to set $GH_REVS var; used in bin/github-pr ####
gh_revs() {
  if [[ -z $(env | grep GH_REVS) ]] ; then
    if [ -f ~/.login-revs ] ; then
      GH_REVS=$(cat ~/.login-revs |
        grep -m 1 "$(basename $(git rev-parse --show-toplevel))" |
        awk '{print $2}')
    else
      GH_REVS="$(git config user.name)"
    fi
  fi
}

#### verify that pip binary exists and that boto3 is installed
boto3_check() {
  echo_blue "Verifying pip / boto3..."
  if [[ ! $(which pip) ]] ; then
    raise 'pip binary not found; verify and retry'
  elif ! [[ $($(which pip) list | grep boto3) ]] ; then
    if ! prompt_yn "boto3 library not found; install via pip?" ; then
      raise 'Install boto3 library and retry'
    else
      $(which pip) install boto3
    fi
  else
    echo_cyan "pip binary found + boto3 library installed."
  fi
}

#### given $TASKS which contains a set of functions to run,
#### echo_green each one and then run it
run_tasks() {
  echo
  [[ -z ${TODO-} ]] && TODO+=("${TASKS[@]}")
  TODO=($(printf '%s\n' "${TODO[@]}"|sort -u))
  for TASK in "${TODO[@]}" ; do
    echo_green "Executing task '${TASK}'..."
    eval ${TASK}
    echo_green "Task completed successfully."
    sleep 1
    echo
  done
}

#### empty bucket including all versions of all objects
empty_bucket_with_versions() {
  local BUCKET_TO_EMPTY=${1}
  ave aws s3 rm s3://${BUCKET_TO_EMPTY} --recursive
  ave python -c "import boto3 ;\
    session = boto3.Session() ;\
    s3 = session.resource(service_name='s3') ;\
    bucket = s3.Bucket('${BUCKET_TO_EMPTY}') ;\
    bucket.object_versions.delete()"
}

#### get id and name of all resources in Terraform state
get_tf_state() {
  STATE_ENV=${1:-$(echo ${TF_ENV})}
  STATE_DIR=${2:-$(echo ${TF_DIR})}
  ${GIT_DIR}/bin/td -e ${STATE_ENV} -d ${STATE_DIR} -s pull -no-color |
    jq '.resources[]|select(.mode == "managed")|
    {id: .instances[0].attributes.id,name: (
      (if .module? then "\(.module)." else "" end) + .type + "." + .name +
      (if .instances[0].index_key? then ("[" + (
      if (.instances[0].index_key|type) == "number"
      then .instances[0].index_key|tostring
      else ("\"" + .instances[0].index_key + "\"") end
      ) + "]") else "" end))}'
}

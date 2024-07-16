#!/bin/bash
# Gitlab Related Shell Functions

set -eu

. "$(dirname "$0")/lib/common.sh"

REVIEWERS=()
declare -a GL_REV_USERS
declare GL_REV_GROUP GL_DATA

verify_gitlab_apps() {
  for GL_APP in 'jq' 'yq' 'glab'; do
    if [[ ! $(which "${GL_APP}") ]]; then
      brew install ${GL_APP} || raise "${GL_APP} not installed!"
    fi
  done
}

load_glab_data() {
  GL_DATA=$(cat ${GIT_DIR}/terraform/master/global/users.yaml | yq -o json |
    jq -r '.users|to_entries[]|select(.value.aws_groups != null)| {user: .key, git_user: .value.git_username[0], groups: .value.aws_groups}')
}

initialize_library() {
  verify_root_repo
  verify_gitlab_apps
  load_glab_data
}

get_glab_assignee() {
  yq '.hosts."gitlab.login.gov".user' <~/.config/glab-cli/config.yml
}

get_glab_user() {
  local USER_TO_CHECK=$1
  echo ${GL_DATA} | jq -r --arg GL_USER "${USER_TO_CHECK}" \
    '.|select(.user == $GL_USER)|.git_user // .user'
}

get_glab_group() {
  local GROUP_TO_CHECK=$1
  echo ${GL_DATA} | jq -r --arg GL_GROUP "${GROUP_TO_CHECK}" \
    '.|select(.groups[]|contains($GL_GROUP))|.git_user // .user' |
    tr '\n' ',' | sed -E 's/,$/\n/'
}

sanitize_glab_mr_description() {
  local DESCRIPTION=$1
  echo "${DESCRIPTION//$'\n'/<br />}"
}

create_reviewer_list() {
  if [[ ! -z ${GL_REV_GROUP} ]]; then
    REVIEWERS+=($(get_glab_group ${GL_REV_GROUP}))
  fi

  if [[ ! -z "${GL_REV_USERS[@]}" ]]; then
    for USER in $(echo "${GL_REV_USERS[@]}" | tr ',' ' '); do
      GL_USERNAME=$(get_glab_user ${USER})
      if [[ ! "${REVIEWERS[@]:-}" =~ "${GL_USERNAME}" ]] && [[ ! -z ${GL_USERNAME} ]]; then
        REVIEWERS+=(${GL_USERNAME})
      fi
    done
  fi
}

get_reviewer_list_without_assignee() {
  create_reviewer_list
  echo "${REVIEWERS[@]:-}" | tr ' ' ',' | sed -E "s/$(get_glab_assignee),//"
}

initialize_library

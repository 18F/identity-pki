#!/bin/bash

ave() {
  local run_me=("$@")
  if [[ $USE_RUN -gt 0 ]] ; then
    if [ -t 1 ]; then
      echo -ne "\\033[1;36m"
    fi
  
    echo >&2 "+ ${run_me[@]}"
  
    if [ -t 1 ]; then
      echo -ne '\033[m'
    fi
  fi
  aws-vault exec ${AV_PROFILE} -- "${run_me[@]}"
}

verify_private_repo() {
  PRIVATE_REPO=${ID_PRIVATE_DIR-}
  if [[ -z ${PRIVATE_REPO} ]] ; then
    BASENAME="$(basename "$GIT_DIR")"
    PRIVATE_REPO="$(dirname "$GIT_DIR")/$BASENAME-private"
  fi
  if [[ ! -d ${PRIVATE_REPO} ]] ; then
    raise "${PRIVATE_REPO} not found; \
           set \$ID_PRIVATE_DIR env var with correct path"
  fi
  echo_cyan "identity-devops-private dir located."
  export PROTECTED_ENVS=$(grep -rnw 'STRICT_ENVIRONMENT' ${PRIVATE_REPO} |
                        sed -E 's/.+\/env\/([a-z0-9]+)\.sh.+/\1/')
}

verify_env_files() {
  for FILE in "${GIT_DIR}/kitchen/environments/${TF_ENV}.json" \
              "${PRIVATE_REPO}/vars/${TF_ENV}.tfvars" \
              "${PRIVATE_REPO}/chef/environments/${TF_ENV}.json" \
              "${PRIVATE_REPO}/chef/data_bags/users/${TF_ENV}.json" \
              "${PRIVATE_REPO}/env/${TF_ENV}.sh" ; do
    FILENAME=$(echo ${FILE} | awk -F/ '{print $NF}')
    FILEPATH=$(echo ${FILE} | awk -F/ '{$NF=""; print $0}')
    [[ -f "${FILE}" ]] || raise "${FILENAME} not found at ${FILEPATH}"
  done
  echo_cyan "Environment config files exist and are valid."
}

verify_sandbox_env() {
  TF_ENV=${1:-$(echo ${GSA_USERNAME})}
  if [[ -z ${TF_ENV} ]] ; then
    raise "GSA_USERNAME not set; verify and try again"
  elif [[ $(echo ${PROTECTED_ENVS} | grep ${TF_ENV}) ]] ; then
    raise "Cannot run this script against protected environment ${TF_ENV}"
  fi
  echo_cyan "Using '${TF_ENV}' environment."
  verify_env_files
}

initialize() {
  echo
  echo_green "Initializing..."
  
  verify_root_repo
  verify_private_repo
  verify_sandbox_env ${1:-}
  get_arn_role 'sandbox' 'Terraform'
  
  APP_DIR="${GIT_DIR}/terraform/app"
  AWS_ACCT_NUM=$(ave aws sts get-caller-identity | jq -r '.Account')
  AWS_REGION=$(ave aws configure get region --profile ${AV_PROFILE})
}

run_tasks() {
  echo
  [[ -z ${TODO} ]] && TODO+=(${TASKS})
  for TASK in ${TODO[@]} ; do
    echo_green "Executing task '${TASK}'..."
    eval ${TASK}
    echo_green "Task completed successfully."
    echo
  done
}
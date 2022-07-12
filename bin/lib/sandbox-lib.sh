#!/bin/bash

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
  elif [[ $(grep -w 'STRICT_ENVIRONMENT' ${PRIVATE_REPO}/env/${TF_ENV}.sh) ]] ; then
    raise "Cannot run this script against protected environment ${TF_ENV}"
  elif [[ "${TF_ENV}" =~ ^staging|prod$ ]] ; then
    raise "Cannot be run against the login-prod account!"
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
  get_iam 'app' 'sandbox' 'Terraform'
  if [[ ! -z ${AWS_VAULT:-} ]] && [[ ${AWS_VAULT} != ${AV_PROFILE} ]] ; then
    raise "Must use ${AV_PROFILE} profile (detected: ${AWS_VAULT})"
  fi
  
  APP_DIR="${GIT_DIR}/terraform/app"
  AWS_ACCT_NUM=$(ave aws sts get-caller-identity | jq -r '.Account')
  AWS_REGION=$(cat "${PRIVATE_REPO}/env/account_global_${AWS_ACCT_NUM}.sh" |
    grep -m 1 TERRAFORM_STATE_BUCKET_REGION | awk -F'"' '{print $2}')
}

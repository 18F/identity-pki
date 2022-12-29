#!/bin/bash

verify_account_info() {
  echo
  echo_green "Verifying '${AWS_PROFILE}' profile..."
  local USER_INFO=$(aws iam get-user | jq -r '.User.UserName') || true
  [[ -z ${USER_INFO} ]] && raise 'Profile not found (via aws iam get-user)!'
  local ADMIN_POLICY_NAME='AdministratorAccess'
  local ADMIN_POLICY_ARN="arn:aws:iam::aws:policy/${ADMIN_POLICY_NAME}"
  local USER_POLICIES=$(aws iam list-attached-user-policies \
    --user-name ${USER_INFO} | jq -r '.AttachedPolicies[].PolicyArn')
  if [[ ! $(echo "${USER_POLICIES}" | grep "${ADMIN_POLICY_ARN}") ]] ; then
    raise "'${ADMIN_POLICY_NAME}' IAM policy not attached to user '${USER_INFO}' !"
  else
    echo_cyan "IAM user '${USER_INFO}' found; ${ADMIN_POLICY_NAME} policy attached."
  fi

  ACCT_ID=$(aws sts get-caller-identity | jq -r '.Account')
  echo_green "Verifying AWS account ID + env files in terraform/all directory..."
  local TF_ALL_ACCTS=($(find "${GIT_DIR}/terraform/all" \
    -type d -maxdepth 1 -exec basename {} \; | grep -v 'module\|all'))
  for ALL_ACCT in ${TF_ALL_ACCTS[@]} ; do
    if [[ $(grep "${ACCT_ID}" "${GIT_DIR}/terraform/all/${ALL_ACCT}/main.tf") ]] ; then
      TF_ACCT=${ALL_ACCT}
    fi
  done

  if [[ -z {TF_ACCT} ]] ; then
    echo_red "No main.tf file found in terraform/all containing account ID ${ACCT_ID}!"
    raise "Verify account attached to IAM user and try again!"
  elif [[ "${TF_ACCT}" =~ '(prod|sandbox|master)' ]] ; then
    raise 'Cannot edit sandbox/prod/master accounts!'
  else
    echo_cyan "Found: AWS account '${TF_ACCT}' with ID '${ACCT_ID}'."
  fi

  echo_green "Verifying account status..."
  ACCOUNT_ALIAS=$(aws iam list-account-aliases --query AccountAliases --output text)
}

switch_creds() {
  unset AWS_PROFILE
  case ${1} in
    source) get_iam 'all' "${SRC_ACCT}" 'Terraform' ;;
    dest)   AV_PROFILE=${ADMIN_IAM_ROLE}            ;;
  esac
}

get_secrets_bucket() {
  switch_creds ${1}
  SECRETS_BUCKET=$(bin/awsv -x ${AV_PROFILE} aws s3 ls |
  grep '\.secrets\.' | awk '{print $NF}')
}

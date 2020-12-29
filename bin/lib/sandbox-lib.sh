#!/bin/bash

ave() {
  run aws-vault exec ${AV_PROFILE} -- "$@"
}

verify_private_repo() {
  echo_blue "Finding identity-devops-private dir..."
  PRIVATE_REPO=${ID_PRIVATE_DIR-}
  if [[ -z ${PRIVATE_REPO} ]] ; then
    BASENAME="$(basename "$GIT_DIR")"
    PRIVATE_REPO="$(dirname "$GIT_DIR")/$BASENAME-private"
  fi
  if [[ ! -d ${PRIVATE_REPO} ]] ; then
    raise "${PRIVATE_REPO} not found; \
           set \$ID_PRIVATE_DIR env var with correct path"
  fi
  echo_cyan "Found at ${PRIVATE_REPO}"
  export PROTECTED_ENVS=$(grep -rnw 'STRICT_ENVIRONMENT' ${PRIVATE_REPO} |
                        sed -E 's/.+\/env\/([a-z0-9]+)\.sh.+/\1/')
}

verify_env_files() {
  for FILE in "${GIT_DIR}/kitchen/environments/${GSA_USERNAME}.json" \
              "${PRIVATE_REPO}/vars/${GSA_USERNAME}.tfvars" \
              "${PRIVATE_REPO}/chef/environments/${GSA_USERNAME}.json" \
              "${PRIVATE_REPO}/chef/data_bags/users/${GSA_USERNAME}.json" \
              "${PRIVATE_REPO}/env/${GSA_USERNAME}.sh" ; do
    echo_blue "Verifying ${FILE}..."
    FILENAME=$(echo ${FILE} | awk -F/ '{print $NF}')
    FILEPATH=$(echo ${FILE} | awk -F/ '{$NF=""; print $0}')
    [[ -f "${FILE}" ]] || raise "${FILENAME} not found at ${FILEPATH}"
  done
}

verify_sandbox_env() {
  echo_blue "Verifying env name..."
  TF_ENV=${GSA_USERNAME-}
  if [[ -z ${TF_ENV} ]] ; then
    raise "GSA_USERNAME not set; verify and try again"
  elif [[ $(echo ${PROTECTED_ENVS} | grep ${TF_ENV}) ]] ; then
    raise "Cannot run this script against protected environment ${TF_ENV}"
  fi
  echo_cyan "Will be using '${TF_ENV}' environment."
  verify_env_files
}
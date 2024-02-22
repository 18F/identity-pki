#!/bin/bash
# Start the timer
SECONDS=0

export TF_VAR_cluster_name=$1
ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
export TF_VAR_region=us-west-2
BUCKET="login-gov.tf-state.${ACCOUNT}-${TF_VAR_region}"
SCRIPT_BASE=$(dirname "$0")
RUN_BASE=$(pwd)
export AWS_PAGER=

help_me() {
    cat >&2 << EOM
Usage: ${0} <env_name>

Tears down an existing environment.
EOM
  exit 0
}

# Make sure an environment is passed in
check_var() {
  if [ -z $TF_VAR_cluster_name ]; then
    help_me
  elif [ $TF_VAR_cluster_name = "help" ]; then
    help_me
  else
    return 0
  fi
}

init_workspace() {
  unset KUBECONFIG

  # make sure we are all using the same modules
  if [ ! -L .terraform.lock.hcl ] ; then
    rm -f .terraform.lock.hcl
    ln -s ../../.terraform.lock.hcl .
  fi

  terraform init -backend-config="bucket=$BUCKET" \
    -backend-config="key=terraform-review-app/terraform-${TF_VAR_cluster_name}.tfstate" \
    -backend-config="dynamodb_table=terraform_locks" \
    -backend-config="region=$TF_VAR_region"
}

# Tears down cluster and supporting resources
terraform_destroy() {
  terraform destroy
}

check_var
init_workspace
terraform_destroy

# Calculate and print the total time taken
total_time=$SECONDS
printf "\nTotal Time Taken: %02dh %02dm %02ds\n" $(($total_time / 3600)) $(($total_time % 3600 / 60)) $(($total_time % 60))
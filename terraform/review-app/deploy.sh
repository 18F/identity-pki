#!/bin/bash
# Start the timer
SECONDS=0

# GLOBAL VARS 
export TF_VAR_cluster_name=$1
ACCOUNT_ID=$(aws sts get-caller-identity --query 'Account' --output text)
GITHUB_ORG=$(git config --get remote.origin.url | awk -F ':' '{print $2}' | awk -F '/' '{print $1}')
export TF_VAR_region=us-west-2
BUCKET="login-gov.tf-state.${ACCOUNT_ID}-${TF_VAR_region}"
export AWS_PAGER=

# Check if backend exists for terraform
check_backend() {
  if aws s3 ls "s3://$BUCKET" 2>&1 | grep -q 'NoSuchBucket'; then
      echo "Bucket $BUCKET does not exist. Creating it now..."
      aws s3api create-bucket --bucket "$BUCKET" --create-bucket-configuration LocationConstraint=$TF_VAR_region
      echo "Bucket $BUCKET created successfully."
  else
      echo "Bucket $BUCKET already exists."
  fi
}

# Help function
help_me() {
    cat >&2 << EOM

Usage: ${0} <env_name>

Stands up an environment from scratch.

EOM
  exit 0
}

# Check to make sure an environment was passed in
check_var() {
  if [ -z $TF_VAR_cluster_name ]
  then
    help_me
  elif [ $TF_VAR_cluster_name = "help" ]
  then
    help_me
  else
    return 0
  fi
}

# Switch to the appropriate workspace and run terraform apply
terraform_apply() {
  # Make sure kubeconfig isn't set otherwise it breaks the other providers
  unset KUBECONFIG

  # make sure we are all using the same modules
  if [ ! -L .terraform.lock.hcl ] ; then
    rm -f .terraform.lock.hcl
    ln -s ../../.terraform.lock.hcl .
  fi

  echo "Running init"
  terraform init -reconfigure \
    -backend-config="bucket=$BUCKET" \
    -backend-config="key=terraform-review-app/terraform-${TF_VAR_cluster_name}.tfstate" \
    -backend-config="dynamodb_table=terraform_locks" \
    -backend-config="region=$TF_VAR_region"
  terraform apply
}

# Setup new kubeconfig file for EKS
setup_kubeconfig() {
  # Setup our new kubeconfig file for EKS
  aws eks update-kubeconfig --name $TF_VAR_cluster_name --region $TF_VAR_region
  kubectl config use-context arn:aws:eks:$TF_VAR_region:$ACCOUNT_ID:cluster/$TF_VAR_cluster_name
}

# Make sure environment is given, and backend exists
check_var
check_backend

# Run our terraform
terraform_apply

# Setup our kubeconfig
setup_kubeconfig

# Calculate and print the total time taken
total_time=$SECONDS
printf "\nTotal Time Taken: %02dh %02dm %02ds\n" $(($total_time / 3600)) $(($total_time % 3600 / 60)) $(($total_time % 60))

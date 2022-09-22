#!/bin/sh
# shellcheck disable=SC2034

# These variables are used by `deploy` to pass through information to
# `configure_state_bucket.sh` about where the terraform remote state backend is
# located, which is needed to create the remote state bucket. This duplicates
# information that is already present in the main.tf. Ideally we would find
# some way to share instead.

aws_account_id="555546682965"

# Bucket where terraform state is stored
TERRAFORM_STATE_BUCKET_REGION="us-west-2"
TERRAFORM_STATE_BUCKET="login-gov.tf-state.$aws_account_id-$TERRAFORM_STATE_BUCKET_REGION"

# set to '0' to alert if deploying outside of bootstrap_main_git_ref_default
# ONLY set this to '1' in strict environments (int/staging/prod)
export STRICT_ENVIRONMENT=1

# used by `deploy` to pass to configure_state_bucket.sh
ID_state_lock_table=terraform_locks


#!/bin/sh
# shellcheck disable=SC2034

# These variables are used by `deploy` to pass through information to
# `configure_state_bucket.sh` about where the terraform remote state backend is
# located, which is needed to create the remote state bucket. This duplicates
# information that is already present in the main.tf. Ideally we would find
# some way to share instead.

aws_account_id="472911866628"

# Bucket where terraform state is stored
TERRAFORM_STATE_BUCKET_REGION="us-east-1"
TERRAFORM_STATE_BUCKET="login-gov.tf-state.$aws_account_id-$TERRAFORM_STATE_BUCKET_REGION"

# used by `deploy` to pass to configure_state_bucket.sh
ID_state_lock_table=terraform_locks

# default AWS credentials profile for this account
if [ -z "${AWS_PROFILE-}${AWS_ACCESS_KEY_ID-}" ]; then
    export AWS_PROFILE="sms.login.gov"
fi

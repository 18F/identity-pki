#!/bin/sh
#
# This script destroys the environment.
# 
set -e

if [ -z "$1" ] || [ "$2" != "-yesreallydestroyit" ]; then
     echo "usage:   $0 <cluster_name> -yesreallydestroyit"
     echo "example: $0 loadtest2 -yesreallydestroyit"
     exit 1
else
     export TF_VAR_cluster_name="$1"
fi

ACCOUNT=$(aws sts get-caller-identity | jq -r .Account)
export TF_VAR_region="us-west-2"
BUCKET="login-gov.tf-state.${ACCOUNT}-${TF_VAR_region}"
SCRIPT_BASE=$(dirname "$0")
RUN_BASE=$(pwd)

# set it up with the s3 backend
cd "$RUN_BASE/$SCRIPT_BASE"
terraform init -backend-config="bucket=$BUCKET" \
      -backend-config="key=terraform-review-app/terraform-${TF_VAR_cluster_name}.tfstate" \
      -backend-config="dynamodb_table=terraform_locks" \
      -backend-config="region=$TF_VAR_region"

# burn it downnnnnnnn
terraform destroy


#!/usr/bin/env bash

if [ $# -ne 2 ] ; then
    echo "Usage: $0 <bucket_name> <state_file_path>"
    echo "  Configure terraform to store state in s3."
    exit 1
fi

BUCKET=$1
STATE=$2

echo "Using state file $STATE"

echo "Creating an s3 bucket for terraform state"
# Do not create the bucket if it contains underscores. See
# https://github.com/18F/identity-private/issues/1835
if [[ $BUCKET != *_* ]]
then
  aws s3 mb s3://${BUCKET}
  echo "It contains one of those"
fi

echo "Enabling versioning on the s3 bucket"
aws s3api put-bucket-versioning \
  --bucket ${BUCKET} \
  --versioning-configuration Status=Enabled

echo "Using terraform remote state server"
cd ${TF_DIR}
rm -rf .terraform
# https://github.com/hashicorp/terraform/issues/12762
if [[ "$(terraform --version)" == *"v0.9"* ]]; then
    terraform init \
      -backend-config="bucket=${BUCKET}" \
      -backend-config="key=${STATE}" \
      -backend-config="region=us-east-1"
elif [[ "$(terraform --version)" == *"v0.8"* ]]; then
    terraform remote config -backend=s3 \
      -backend-config="bucket=${BUCKET}" \
      -backend-config="key=${STATE}" \
      -backend-config="region=us-east-1" \
      -state="${STATE}"
else
    echo "ERROR: Unsupported terraform version"
    exit 1
fi

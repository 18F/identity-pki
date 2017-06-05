#!/usr/bin/env bash

set -eu

if [ $# -ne 3 ] ; then
  cat >&2 <<EOM
Usage: $0 <bucket_name> <state_file_path> <terraform_dir>

Configure terraform to store state in s3.

The <terraform_dir> should contain terraform files, (e.g. main.tf).

WARNING: this script will \`rm -rf' any .terraform directory present under the
terraform_dir, so be careful about where you run this from.
EOM
exit 1
fi

BUCKET=$1
STATE=$2
TF_DIR=$3

run() {
    echo >&2 "+ $*"
    "$@"
}
terraform() {
  echo >&2 "+ terraform $*"
  command terraform "$@"
}
aws() {
  echo >&2 "+ aws $*"
  command aws "$@"
}

echo "Using state file $STATE"

echo "Creating an s3 bucket for terraform state"
# Do not create the bucket if it contains underscores. See
# https://github.com/18F/identity-private/issues/1835
if [[ $BUCKET != *_* ]]
then
  # TODO: don't try to create the bucket if it already exists
  aws s3 mb "s3://$BUCKET"
  echo "It contains one of those"
fi

echo "Enabling versioning on the s3 bucket"
aws s3api put-bucket-versioning \
  --bucket "$BUCKET" \
  --versioning-configuration Status=Enabled

echo "Using terraform remote state server"
echo "Deleting ${TF_DIR}/.terraform"
cd "${TF_DIR}"
run rm -rfv .terraform

# https://github.com/hashicorp/terraform/issues/12762
case "$(CHECKPOINT_DISABLE=1 terraform --version)" in
  *v0.9.*)
    terraform init \
      -backend-config="bucket=${BUCKET}" \
      -backend-config="key=${STATE}" \
      -backend-config="region=us-east-1"
    ;;
  *v0.8.*)
    terraform remote config -backend=s3 \
      -backend-config="bucket=${BUCKET}" \
      -backend-config="key=${STATE}" \
      -backend-config="region=us-east-1" \
      -state="${STATE}"
    ;;
  *)
    echo "ERROR: Unsupported terraform version"
    exit 1
    ;;
esac

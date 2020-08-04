#!/usr/bin/env bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [[ $# != 1 ]]; then
    cat >&2 <<EOM
Usage: $(basename "$0") <environment>

Print version information about the latest terraform/app applied to the given
environment. This metadata includes git revision and timestamp info about the
last terraform apply that was done from identity-devops:/terraform/app/.

This information is stored in S3 next to the terraform state files. Terraform
apply will automatically change this information when it is run.

See https://github.com/18F/identity-devops/tree/master/doc/process/releases.md
for more details about our release tools.
EOM
    exit 1
fi

ENVIRONMENT="$1"

if [ ! -d 'terraform/all' ]; then
  echo "This must be run from the root of the identity-devops repo"
  exit 1
fi

# Sources terraform/core environment setup file to find correct bucket.
case "${ENVIRONMENT}" in
  prod|staging)
    . terraform/all/prod/env-vars.sh
    ;;
  *)
    . terraform/all/sandbox/env-vars.sh
    ;;
esac

VERSION_INFO_PATH="s3://${TERRAFORM_STATE_BUCKET}/terraform-app"

echo >&2 "Version info for ${ENVIRONMENT}:"
set -x
aws s3 cp "$VERSION_INFO_PATH/version_info/${ENVIRONMENT}.txt" -

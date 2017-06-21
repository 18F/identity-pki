#!/usr/bin/env bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [[ $# != 1 ]]; then
    cat >&2 <<EOM
Usage: $(basename "$0") <environment>

Print version information about the latest terraform-app applied to the given
environment. This metadata includes git revision and timestamp info about the
last terraform apply that was done from identity-devops:/terraform-app/.

This information is stored in S3 next to the terraform state files. Terraform
apply will automatically change this information when it is run.

See https://github.com/18F/identity-devops/tree/master/doc/process/releases.md
for more details about our release tools.
EOM
    exit 1
fi

ENVIRONMENT="$1"

VERSION_INFO_PATH="s3://login_dot_gov_tf_state/terraform-app"

echo >&2 "Version info for ${ENVIRONMENT}:"
set -x
aws s3 cp "$VERSION_INFO_PATH/version_info/$ENVIRONMENT.txt" -

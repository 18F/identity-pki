#!/bin/bash
set -euo pipefail

# Runs the shellcheck command on scripts in this repo
# Forwards arguments to shellcheck directly, such as --format=diff

if ! which shellcheck > /dev/null; then
  echo "shellcheck not installed, use apt or brew to install it"
  exit 1
fi

shellcheck --version

to_fix=(
  bin/awsv
  bin/break-glass/emergency-maintenance-mode
  bin/break-glass/revoke-user-access.sh
  bin/break-glass/switch-modules
  bin/build-images
  bin/create-aws-creds
  bin/create-sandbox
  bin/deploy/get-version-info.sh
  bin/destroy-data-warehouse
  bin/destroy-sandbox
  bin/disable-autotf
  bin/disaster-recovery/db-get-restore-points
  bin/disaster-recovery/db-swap-clusters
  bin/enable-autotf
  bin/follow-images
  bin/get-aws-roles
  bin/get-images
  bin/kms-matching-toggle
  bin/kms-matching.sh
  bin/lambda-utilities/lint.sh
  bin/lambda-utilities/test.sh
  bin/lib/acct-lib.sh
  bin/lib/common.sh
  bin/lib/dotfiles/login-functions
  bin/lib/dotfiles/subfunctions
  bin/lib/gitlab.sh
  bin/lib/sandbox-lib.sh
  bin/local-doctor
  bin/new-user-setup
  bin/oneoffs/blockhub.sh
  bin/oneoffs/build-dm-from-prod
  bin/oneoffs/clean-slate
  bin/oneoffs/create-aws-account
  bin/oneoffs/generate-saml-cert.sh
  bin/oneoffs/get-repos
  bin/oneoffs/login-alias
  bin/oneoffs/region-failover
  bin/oneoffs/speedy-saml
  bin/pocust
  bin/rm-merged-branches
  bin/ssm-command
  bin/td
  bin/terraform-bundle.sh
  bin/terraform-switch.sh
  bin/tfp-update
  bin/tfplan
  bin/users/sync.sh
  dockerfiles/env_deploy.sh
  dockerfiles/env_stop.sh
  dockerfiles/env_test.sh
  dockerfiles/gitlab_test.sh
  dockerfiles/terraform_apply.sh
  dockerfiles/terraform_plan.sh
  kitchen/cookbooks/identity-locust/files/default/id-locust
  terraform/app/recycle.sh
  terraform/gitlab/asg-disable.sh
  terraform/gitlab/push-gitlab-runner-allowed-images.sh
  terraform/gitlab/recycle.sh
  terraform/gitlab/sign-gitlab-runner-images.sh
  terraform/gitlab/tests/test.sh
  terraform/gitlab/update-gitlab-runner-allowed-images.sh
  terraform/modules/bootstrap/provision.sh
  tests/test.sh
)

sh_files=$(find . -name "*.sh" | grep -v "vendor")
shebang_files=$(grep -R -l "#\!/bin/bash" . | grep -v "vendor" | grep -v ".sh" |  grep -v ".erb" | grep -v ".rb" | grep -v ".git")

echo "$sh_files" "$shebang_files" \
  | grep -vFf <(printf '%s\n' "${to_fix[@]}") \
  | xargs shellcheck "$@"

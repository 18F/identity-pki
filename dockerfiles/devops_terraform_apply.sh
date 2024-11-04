#!/bin/bash -x
#
# Deploy an environment from gitlab job.
# If this is not going to be deployed to us-west-2, you will need to set
# AWS_REGION.  Your job might need to set GIT_SUBMODULE_STRATEGY: normal.
#

set -e

# sanity check
if [ -z "$CI_PROJECT_DIR" ]; then
  echo "not being run under gitlab CI, so nothing will work:  aborting"
  exit 1
fi

# set up variables
AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_REGION
INCLUDE_BASE_FILE=${INCLUDE_BASE_FILE:-false}
AWS_ACCOUNTID="$(aws sts get-caller-identity --output text --query 'Account')"
TFSTATE_BUCKET="login-gov.tf-state.$AWS_ACCOUNTID-$AWS_REGION"
TFSTATE_CONFIG_KEY="terraform-$TERRAFORM_DIR/$ENV_NAME.tfstate"
PRIVATE_REPO_DIR="$CI_PROJECT_DIR/identity-devops-private"

# Check for valid Terraform Directories
case $TERRAFORM_DIR in
all | app | core | data-warehouse | ecr | gitlab | imagebuild | logarchive | master | sms | tooling | waf) echo Terraform directory is set to "$TERRAFORM_DIR" ;;
*)
  echo Terraform directory is set to "$TERRAFORM_DIR", which is not allowed
  exit 1
  ;;
esac

# We need to use a tfbundle so that we don't have to have access to the internet.
cd "$CI_PROJECT_DIR"
mkdir -p "terraform/$TERRAFORM_DIR/$ENV_NAME/.terraform"
cp -rp /terraform-bundle/plugins "terraform/$TERRAFORM_DIR/$ENV_NAME/.terraform/"

# Deal with our wacky provider locking scheme
rm -f "terraform/$TERRAFORM_DIR/$ENV_NAME/.terraform.lock.hcl"
cp .terraform.lock.hcl "terraform/$TERRAFORM_DIR/$ENV_NAME"
rm -f "terraform/$TERRAFORM_DIR/$ENV_NAME/versions.tf"
rm -f terraform/modules/newrelic/versions.tf # XXX I am not sure why we have to do this.
cp versions.tf terraform/modules/newrelic/   # XXX symlinks should work

# make sure that we have checked out main for the identity-devops-private submodule
# and set up some other git stuff
git config --global --add safe.directory "$CI_PROJECT_DIR"
git config --global --add safe.directory "$PRIVATE_REPO_DIR"
cd "$PRIVATE_REPO_DIR"
git checkout main

# set up env vars
TF_VAR_env_name="$CI_ENVIRONMENT_NAME"
export TF_VAR_env_name
TF_VAR_account_id="$AWS_ACCOUNTID"
export TF_VAR_account_id
TF_VAR_privatedir="$PRIVATE_REPO_DIR"
export TF_VAR_privatedir

# Do the init
cd "$CI_PROJECT_DIR/terraform/$TERRAFORM_DIR/$ENV_NAME" || exit 1
/usr/local/bin/terraform init -plugin-dir=.terraform/plugins \
  -lockfile=readonly \
  -backend-config=bucket="$TFSTATE_BUCKET" \
  -backend-config=key="$TFSTATE_CONFIG_KEY" \
  -backend-config=dynamodb_table=terraform_locks \
  -backend-config=region="$AWS_REGION"
/usr/local/bin/terraform providers lock -fs-mirror=.terraform/plugins

# plan, so we can create/store a plan artifact
varFiles=()
ACCOUNT_GLOBAL_FILE="$PRIVATE_REPO_DIR/vars/account_global_$AWS_ACCOUNTID.tfvars"
BASE_GLOBAL_FILE="$PRIVATE_REPO_DIR/vars/base.tfvars"
[[ $INCLUDE_BASE_FILE = true ]] && varFiles+=("-var-file $BASE_GLOBAL_FILE")
[[ -f $ACCOUNT_GLOBAL_FILE ]] && varFiles+=("-var-file $ACCOUNT_GLOBAL_FILE")
/usr/local/bin/terraform plan -lock-timeout=180s -out="$CI_PROJECT_DIR/terraform.plan" "${varFiles[@]}"
/usr/local/bin/terraform show -no-color "$CI_PROJECT_DIR/terraform.plan" >"$CI_PROJECT_DIR/plan.txt"

JQSTUFF='([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}'
/usr/local/bin/terraform show --json "$CI_PROJECT_DIR/terraform.plan" | jq -r "$JQSTUFF" >"$CI_PROJECT_DIR/plan.json"

# deploy, using the plan
/usr/local/bin/terraform apply -lock-timeout=180s -auto-approve "$CI_PROJECT_DIR/terraform.plan"
echo terraform apply completed on "$(date)"

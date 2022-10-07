#!/bin/bash -x
# 
# Deploy an idp environment from gitlab job.
# If this is not going to be deployed to us-west-2, you will need to set
# AWS_REGION.  Your job might need to set GIT_SUBMODULE_STRATEGY: normal.
# 

set -e

# sanity check
if [ -z "$CI_PROJECT_DIR" ] ; then
	echo "not being run under gitlab CI, so nothing will work:  aborting"
	exit 1
fi
if [ "$MY_ENV" != "$CI_ENVIRONMENT_NAME" ] ; then
	echo "gitlab is asking us to deploy to $CI_ENVIRONMENT_NAME, but I am in $MY_ENV.  Aborting"
	exit 2
fi
var="MY_ENV_$CI_ENVIRONMENT_NAME"
if [ -z "${!var}" ] ; then
	echo "gitlab is asking us to deploy to $CI_ENVIRONMENT_NAME, but I am not in that environment.  Aborting"
	exit 3
fi
if [ "$(env | grep -Ec '^MY_ENV_')" -gt 1 ] ; then
	echo "something is trying to override what environment we are in, as there is more than one MY_ENV_* variable.  Aborting"
	exit 4
fi


# set up variables
AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_REGION
AWS_ACCOUNTID="$(aws sts get-caller-identity --output text --query 'Account')"
TFSTATE_BUCKET="login-gov.tf-state.$AWS_ACCOUNTID-$AWS_REGION"
TFSTATE_CONFIG_KEY="terraform-app/terraform-$CI_ENVIRONMENT_NAME.tfstate"
IDP_DIR="$CI_PROJECT_DIR/identity-devops-private"

# do recycle early and bail if we are only supposed to be recycling the env runners
if [ -n "$RECYCLE_ENV_RUNNERS_ONLY" ] ; then
	bash "$CI_PROJECT_DIR/terraform/app/recycle.sh" "$CI_ENVIRONMENT_NAME"
	exit $?
fi

# We need to use a tfbundle so that we don't have to have access to the internet.
cd "$CI_PROJECT_DIR"
mkdir -p terraform/app/.terraform
cp -rp /terraform-bundle/plugins terraform/app/.terraform/

# Deal with our wacky provider locking scheme
rm -f terraform/app/.terraform.lock.hcl
cp .terraform.lock.hcl terraform/app
rm -f terraform/app/versions.tf
cp versions.tf terraform/app
rm -f terraform/modules/newrelic/versions.tf  # XXX I am not sure why we have to do this.
cp versions.tf terraform/modules/newrelic/    # XXX symlinks should work

# make sure that we have checked out main for the identity-devops-private submodule
# and set up some other git stuff
git config --global --add safe.directory "$CI_PROJECT_DIR"
git config --global --add safe.directory "$IDP_DIR"
cd "$IDP_DIR"
git checkout main

# set up env vars
TF_VAR_env_name="$CI_ENVIRONMENT_NAME"
export TF_VAR_env_name
TF_VAR_account_id="$AWS_ACCOUNTID"
export TF_VAR_account_id
TF_VAR_privatedir="$IDP_DIR"
export TF_VAR_privatedir
NEW_RELIC_API_KEY=$(aws s3 cp "s3://login-gov.secrets.$AWS_ACCOUNTID-$AWS_REGION/common/newrelic_apikey" - || true)
export NEW_RELIC_API_KEY

# start RDS/aurora (it may be shut down from an env_stop)
aws rds start-db-instance --region "$AWS_REGION" --db-instance-identifier "$CI_ENVIRONMENT_NAME-idp-worker-jobs" || true
aws rds start-db-instance --region "$AWS_REGION" --db-instance-identifier "login-$CI_ENVIRONMENT_NAME" || true
aws rds start-db-instance --region "$AWS_REGION" --db-instance-identifier "login-$CI_ENVIRONMENT_NAME-idp" || true
aws rds start-db-instance --region "$AWS_REGION" --db-instance-identifier "$CI_ENVIRONMENT_NAME-idp-replica" || true
aws rds start-db-cluster --region "$AWS_REGION" --db-cluster-identifier "login-$CI_ENVIRONMENT_NAME-idp-aurora-$AWS_REGION" || true

# Do the init
cd "$CI_PROJECT_DIR/terraform/app" || exit 1
/usr/local/bin/terraform init -plugin-dir=.terraform/plugins \
	-lockfile=readonly \
	-backend-config=bucket="$TFSTATE_BUCKET" \
	-backend-config=key="$TFSTATE_CONFIG_KEY" \
	-backend-config=dynamodb_table=terraform_locks \
	-backend-config=region="$AWS_REGION"
/usr/local/bin/terraform providers lock -fs-mirror=.terraform/plugins

# plan, so we can create/store a plan artifact
/usr/local/bin/terraform plan -lock-timeout=180s -out="$CI_PROJECT_DIR/terraform.plan" \
		-var-file "$IDP_DIR/vars/base.tfvars" \
		-var-file "$IDP_DIR/vars/account_global_$AWS_ACCOUNTID.tfvars" \
		-var-file "$IDP_DIR/vars/$CI_ENVIRONMENT_NAME.tfvars"
/usr/local/bin/terraform show -no-color "$CI_PROJECT_DIR/terraform.plan" > "$CI_PROJECT_DIR/plan.txt"

JQSTUFF='([.resource_changes[]?.change.actions?]|flatten)|{"create":(map(select(.=="create"))|length),"update":(map(select(.=="update"))|length),"delete":(map(select(.=="delete"))|length)}'
/usr/local/bin/terraform show --json "$CI_PROJECT_DIR/terraform.plan" | jq -r "$JQSTUFF" > "$CI_PROJECT_DIR/plan.json"

# deploy, using the plan
/usr/local/bin/terraform apply -lock-timeout=180s -auto-approve "$CI_PROJECT_DIR/terraform.plan"
echo terraform apply completed on "$(date)"

# recycle the nodes
bash "$CI_PROJECT_DIR/terraform/app/recycle.sh" "$CI_ENVIRONMENT_NAME"

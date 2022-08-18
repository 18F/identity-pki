#!/bin/sh -x
# 
# test a gitlab environment from gitlab job.
# If this is not going to be deployed to us-west-2, you will need to set
# AWS_REGION.  This should be run with IAM permissions that just let it
# do the test stuff. 
# 

# sanity check
if [ -z "$CI_PROJECT_DIR" ] ; then
	echo "not being run under gitlab CI, so nothing will work:  aborting"
	exit 1
fi
if [ -z "$DOMAIN" ] ; then
	echo "need to set DOMAIN to the hostname of the gitlab server, like gitlab.login.gov, for this to work:  aborting"
	exit 2
fi
if [ -z "$ENV_NAME" ] ; then
	echo "need to set ENV_NAME for this to work:  aborting"
	exit 2
fi


# set up variables
AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_REGION
export REGION="$AWS_REGION"
ACCOUNTID=${ACCOUNTID:=$(aws sts get-caller-identity --query 'Account' --output text)}
export ACCOUNTID

cd "$CI_PROJECT_DIR/terraform/gitlab/tests"
mkdir "$CI_PROJECT_DIR/testlogs"

go test -v -timeout 30m > "$CI_PROJECT_DIR/test_output.log"
RETVAL=$?

cat "$CI_PROJECT_DIR/test_output.log"

/usr/local/bin/terratest_log_parser --testlog "$CI_PROJECT_DIR/test_output.log" --outputdir "$CI_PROJECT_DIR/testlogs"

exit $RETVAL

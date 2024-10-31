#!/bin/bash -x
#
# Refresh target EC2 ASG instances from gitlab job.
# If this is not going to be deployed to us-west-2, you will need to set
# AWS_REGION.

set -e

# sanity check
if [ -z "$CI_PROJECT_DIR" ]; then
  echo "not being run under gitlab CI, so nothing will work:  aborting"
  exit 1
fi

# set up variables
AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_REGION

# Validate ASG Target and Find Closest Match.
CI_ASG_TARGET=$(aws autoscaling describe-auto-scaling-groups --query "AutoScalingGroups[?contains(AutoScalingGroupName, '$CI_ASG_TARGET')].AutoScalingGroupName | [0]" --output text)

aws autoscaling start-instance-refresh --auto-scaling-group-name "$CI_ASG_TARGET" >"/tmp/refresh-details"
REFRESHID=$(jq -r .InstanceRefreshId <"/tmp/refresh-details")
echo "============= checking $CI_ASG_TARGET $REFRESHID"

STOP=false
FAILURE=false
until [ "$STOP" = true ]; do
  STATUS=$(aws autoscaling describe-instance-refreshes --region "$AWS_REGION" --auto-scaling-group-name "$CI_ASG_TARGET" --instance-refresh-ids "$REFRESHID" | jq -r '.InstanceRefreshes[] | .Status')

  case "$STATUS" in
  "Successful")
    echo "$CI_ASG_TARGET recycle succeeded"
    STOP=true
    ;;
  "Failed")
    echo "$CI_ASG_TARGET failed to recycle"
    STOP=true
    FAILURE=true
    ;;
  "Cancelled")
    echo "$CI_ASG_TARGET reycle was canceled for some reason:"
    aws autoscaling describe-instance-refreshes --region "$AWS_REGION" --auto-scaling-group-name "$CI_ASG_TARGET" --instance-refresh-ids "$REFRESHID"
    STOP=true
    FAILURE=true
    ;;
  *)
    # show the status here while we are waiting
    aws autoscaling describe-instance-refreshes --region "$AWS_REGION" --auto-scaling-group-name "$CI_ASG_TARGET" --instance-refresh-ids "$REFRESHID"
    sleep 60
    ;;
  esac
done

if [ "$FAILURE" = "true" ]; then
  echo "node recycle FAILED, investigate reasons above"
  exit 1
fi

#!/bin/bash -x
#
# Launch target EC2 ASG migration instances from gitlab job.
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
MIGRATIONDURATION=${MIGRATIONDURATION:15}
export MIGRATIONDURATION
export AWS_REGION

CURRENTSIZE=$(aws autoscaling describe-auto-scaling-groups --region "$AWS_REGION" --auto-scaling-group-names "$CI_ASG_TARGET" | jq .AutoScalingGroups[0].DesiredCapacity)
DESIREDSIZE=$((CURRENTSIZE + 1))

if [ "$(uname -s)" = "Darwin" ]; then
  NOW=$(TZ=Zulu date -v +15S +%Y-%m-%dT%H:%M:%SZ)
  THEFUTURE=$(TZ=Zulu date -v +"$MIGRATIONDURATION"M +%Y-%m-%dT%H:%M:%SZ)
else
  NOW=$(TZ=Zulu date -d "15 seconds" +%Y-%m-%dT%H:%M:%SZ)
  THEFUTURE=$(TZ=Zulu date -d "$MIGRATIONDURATION minutes" +%Y-%m-%dT%H:%M:%SZ)
fi
echo "============= Scheduling migration host launch and teardown"
aws autoscaling put-scheduled-update-group-action --region "$AWS_REGION" --scheduled-action-name "migrate-$ENV_NAME" --auto-scaling-group-name "$CI_ASG_TARGET" --start-time "$NOW" --desired-capacity "$DESIREDSIZE"
aws autoscaling put-scheduled-update-group-action --region "$AWS_REGION" --scheduled-action-name "end-migrate-$ENV_NAME" --auto-scaling-group-name "$CI_ASG_TARGET" --start-time "$THEFUTURE" --desired-capacity 0
echo "============= Monitoring migration host status"

# Wait for instances
InstanceID=""
until [ -n "$InstanceID" ]; do
  sleep 10
  instances=$(aws autoscaling describe-auto-scaling-instances --query "AutoScalingInstances[?AutoScalingGroupName=='$CI_ASG_TARGET']")
  InstanceID=$(echo "$instances" | jq -r '.[].InstanceId')
done

# Check Status
until [ "$STOP" = true ]; do
  LifecycleState=$(aws autoscaling describe-auto-scaling-instances --instance-ids "$InstanceID" | jq -r '.AutoScalingInstances[].LifecycleState')

  case "$LifecycleState" in
  "InService" | "Terminating")
    echo "$CI_ASG_TARGET has finished"
    STOP=true
    ;;
  *)
    echo "$InstanceID is current $LifecycleState. Sleeping..."
    sleep 30
    ;;
  esac
done

exit 0

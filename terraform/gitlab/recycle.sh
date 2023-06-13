#!/bin/sh
#
# This script recycles all autoscaling groups in an environment.
#

if [ -z "$1" ] ; then
	echo "usage:    $0 <env_name>"
	echo "example:  $0 tspencer"
	exit 1
fi

set +e

ENV_NAME="$1"
AWS_REGION="${AWS_REGION:-us-west-2}"
export AWS_REGION

# How many minutes to give migrations a head start before doing all the recycles
MIGRATIONDELAY=5
# How many minutes to wait for a migration to get done and thus be torn down
MIGRATIONDURATION=20

# Healthy percentage required during an instance refresh. Chose this because we
# have only one Gitlab Rails instance, so while it's refreshing, the entire
# environment is down anyway. Setting this to 0% tells AWS that all instances
# may be refreshed at once.
MINHEALTHYPCT=0

# This is a egrep pattern for excluding types of ASGs from being recycled.
# Migrations hosts need to be done separately.  You can add more with |.
# Don't kill the runner which may be running this script!
IGNORE="^${ENV_NAME}-migration$|^${ENV_NAME}-gitlab-env-runner"

# clean up
cd /tmp/ || exit 1
rm -rf refreshes*

# determine ASGs to recycle
if [ -n "$RECYCLE_ENV_RUNNERS_ONLY" ]; then
    ASGS="${ENV_NAME}-gitlab-env-runner"
else
    ASGS=$(aws autoscaling describe-auto-scaling-groups --region "$AWS_REGION" | jq -r ".AutoScalingGroups[] | .AutoScalingGroupName | select(test(\"^${ENV_NAME}-\"))" | grep -Ev "$IGNORE")
fi

# start recycles up
for line in $ASGS; do
	aws autoscaling start-instance-refresh --region "$AWS_REGION" --preferences '{"MinHealthyPercentage": '$MINHEALTHYPCT', "InstanceWarmup": 0}' --auto-scaling-group-name "$line" > "/tmp/refreshes-$line"
	if [ "$?" -eq "0" ] ; then
		echo "$line instance refresh initiated"
	else
		echo "error occurred while recycling $line, not going to wait for it"
		rm -f "/tmp/refreshes-$line"
	fi
done

# wait until recycles are done
# XXX this loop works, but it jest kinda growed up ugly as the edge cases were discovered.
FAILURE=false
for i in refreshes* ; do
	# handle case where all refreshes fail.
	if [ "$i" = "refreshes*" ] ; then
		echo "all refreshes FAILED.  Something is probably wrong."
		exit 1
	fi

	# otherwise, loop through the different instance refreshes and check the status
	ASG=$(echo "$i" | sed 's/^refreshes-//')
	REFRESHID=$(jq -r .InstanceRefreshId < "$i")
	echo "============= checking $ASG $REFRESHID"

	STOP=false
	until [ "$STOP" = true ] ; do
		STATUS=$(aws autoscaling describe-instance-refreshes --region "$AWS_REGION"  --auto-scaling-group-name "$ASG" --instance-refresh-ids "$REFRESHID" | jq -r '.InstanceRefreshes[] | .Status')

		case "$STATUS" in
			"Successful")
				echo "$ASG recycle succeeded"
				STOP=true
				;;
			"Failed")
				echo "$ASG failed to recycle"
				STOP=true
				FAILURE=true
				;;
			"Cancelled")
				echo "$ASG reycle was canceled for some reason:"
				aws autoscaling describe-instance-refreshes --region "$AWS_REGION"  --auto-scaling-group-name "$ASG" --instance-refresh-ids "$REFRESHID"
				STOP=true
				FAILURE=true
				;;
			*)
				# show the status here while we are waiting
				aws autoscaling describe-instance-refreshes --region "$AWS_REGION"  --auto-scaling-group-name "$ASG" --instance-refresh-ids "$REFRESHID"
				sleep 60
				;;
		esac
	done
	echo "============= $ASG completed"
done

if [ "$FAILURE" = "true" ] ; then
	echo "node recycle FAILED, investigate reasons above"
	exit 1
fi
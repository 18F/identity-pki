#!/bin/sh
#
# This script recycles all autoscaling groups in an environment.
#

if [ -z "$1" ] ; then
	echo "usage:    $0 <env_name>"
	echo "example:  $0 tspencer"
	exit 1
fi

ENV_NAME="$1"

# this is a egrep pattern for excluding types of ASGs from being recycled
IGNORE="^${ENV_NAME}-migration$"

# clean up
cd /tmp/ || exit 1
rm -rf refreshes*

# start recycles up
aws autoscaling describe-auto-scaling-groups | jq -r ".AutoScalingGroups[] | .AutoScalingGroupName | select(test(\"^${ENV_NAME}-\"))" | egrep -v "$IGNORE" | while read line ; do
	aws autoscaling start-instance-refresh --auto-scaling-group-name "$line" > "/tmp/refreshes-$line"
	if [ "$?" -eq "0" ] ; then
		echo "$line instance refresh initiated"
	else
		echo "error occurred while recycling $line, not going to wait for it"
		rm -f "/tmp/refreshes-$line"
	fi
done

# wait until recycles are done
FAILURE=false
for i in refreshes* ; do
	ASG=$(echo "$i" | sed 's/^refreshes-//')
	REFRESHID=$(jq -r .InstanceRefreshId < "$i")
	echo "============= checking $ASG $REFRESHID"

	STOP=false
	until [ "$STOP" = true ] ; do
		STATUS=$(aws autoscaling describe-instance-refreshes  --auto-scaling-group-name "$ASG" --instance-refresh-ids "$REFRESHID" | jq -r '.InstanceRefreshes[] | .Status')

		case "$STATUS" in
			"Successful")
				STOP=true
				;;
			"Failed")
				echo "$ASG failed to recycle"
				STOP=true
				FAILURE=true
				;;
			*)
				# show the status here while we are waiting
				aws autoscaling describe-instance-refreshes  --auto-scaling-group-name "$ASG" --instance-refresh-ids "$REFRESHID"
				sleep 30
				;;
		esac
	done
	echo "============= $ASG completed"
done

if [ "$FAILURE" = "true" ] ; then
	exit 1
fi

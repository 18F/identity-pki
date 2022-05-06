#!/bin/sh
#
# This script disables all autoscaling groups in an environment.
#

if [ -z "$1" ] ; then
	echo "usage:    $0 <env_name>"
	echo "example:  $0 tspencer"
	exit 1
fi

ENV_NAME="$1"

echo "This will disable all autoscaling groups for environment: ${ENV_NAME}"
read -r -p "Are you sure? [Y/N] " response
case "$response" in
    [yY][eE][sS]|[yY])
				aws autoscaling describe-auto-scaling-groups | jq -r ".AutoScalingGroups[] | .AutoScalingGroupName | select(test(\"^${ENV_NAME}-\"))" | while read line ; do
					aws autoscaling update-auto-scaling-group --min-size 0 --max-size 0 --desired-capacity 0 --auto-scaling-group-name "$line"
					echo "Disabling -> $line"
				done
        ;;
    *)
        echo "cancelled..."
        ;;
esac

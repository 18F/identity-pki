#!/bin/bash
# 
# stop an idp environment from gitlab job.
# If this is not going to be deployed to us-west-2, you will need to set
# AWS_REGION.
#

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

# scale down ASGs
aws autoscaling describe-auto-scaling-groups --region "$AWS_REGION" | jq -r ".AutoScalingGroups[] | .AutoScalingGroupName | select(test(\"^${CI_ENVIRONMENT_NAME}-\"))" | while read line ; do
	if echo "$line" | grep env-runner ; then
		echo "not restarting env-runner so we can start ourselves up again"
	else
		aws autoscaling update-auto-scaling-group --region "$AWS_REGION"  --desired-capacity 0 --min-size 0 --auto-scaling-group-name "$line"
	fi
	if [ "$?" -eq "0" ] ; then
		echo "$line shutdown completed"
	else
		echo "XXX error occurred while shutting down $line"
	fi
done

# shut down RDS/aurora
RDS_INSTANCES="
	$CI_ENVIRONMENT_NAME-idp-worker-jobs
	login-$CI_ENVIRONMENT_NAME
	login-$CI_ENVIRONMENT_NAME-idp
	$CI_ENVIRONMENT_NAME-idp-replica
"
AURORA_CLUSTERS="login-$CI_ENVIRONMENT_NAME-idp-aurora-$AWS_REGION"

for i in $RDS_INSTANCES ; do
	aws rds stop-db-instance --region "$AWS_REGION" --db-instance-identifier "$i"
done
for i in $AURORA_CLUSTERS ; do
	aws rds stop-db-cluster --region "$AWS_REGION" --db-cluster-identifier "$i"
done

# loop until they are stopped
for i in $RDS_INSTANCES ; do
	STATUS=$(aws rds describe-db-instances --region "$AWS_REGION" --db-instance-identifier "$i" | jq -r '.DBInstances[] | .DBInstanceStatus')
	if [ "$STATUS" != "" ] ; then
		until [ "$(aws rds describe-db-instances --region "$AWS_REGION" --db-instance-identifier "$i" | jq -r '.DBInstances[] | .DBInstanceStatus')" == "stopped" ] ; do
			echo "waiting until $i is stopped (status is $STATUS currently)"
			sleep 20
		done
		echo "$i" is stopped
	fi
done
for i in $AURORA_CLUSTERS ; do
	STATUS=$(aws rds describe-db-clusters --region "$AWS_REGION" --db-cluster-identifier "$i" | jq -r '.DBClusters[] | .Status')
	if [ "$STATUS" != "" ] ; then
		until [ "$(aws rds describe-db-clusters --region "$AWS_REGION" --db-cluster-identifier "$i" | jq -r '.DBClusters[] | .Status')" == "stopped" ] ; do
			echo "waiting until $i is stopped (status is $STATUS currently)"
			sleep 20
		done
		echo "$i" is stopped
	fi
done

echo "all databases shut down"

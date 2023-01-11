#!/bin/bash

AWS_ACCOUNT_ID=$(aws sts get-caller-identity | jq -r .Account)
MY_ENV=$(cat /etc/login.gov/info/env)
S3="s3://login-gov.secrets.${AWS_ACCOUNT_ID}-us-west-2/${MY_ENV}"
NAMESPACE=$(aws s3 cp "$S3/gitlab_metric_namespace" -)
API_TOKEN=$(cat /etc/gitlab/gitlab_root_api_token)
REGION=us-west-2

# get project IDs for identity-idp and identity-devops
curl --header "PRIVATE-TOKEN: $API_TOKEN" --request GET "http://localhost:8080/api/v4/projects" | jq -r '.[] | select(.path_with_namespace == "lg/identity-idp" or .path_with_namespace == "lg/identity-devops") | [.id, .path_with_namespace] | @tsv' | while read line ; do
	projectinfo=($line)
	projectid=${projectinfo[0]}
	projectname=${projectinfo[1]}

	# get job counts and send to cloudwatch
	for i in pending running created waiting_for_resource ; do
		jobcount=$(curl --globoff --header "PRIVATE-TOKEN: $API_TOKEN" \
			"http://localhost:8080/api/v4/projects/$projectid/jobs?scope[]=$i" \
			| jq length)
	 
	    METRIC="$projectname-$i-jobs"
	    aws cloudwatch put-metric-data --region="$REGION" --namespace "$NAMESPACE" --metric-name "$METRIC" --value "$jobcount"
	done
done

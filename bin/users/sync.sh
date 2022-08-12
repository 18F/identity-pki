#!/bin/bash

set -euo pipefail

if [ -z "$3" ] ; then
	echo "usage:  $0 <fqdn_of_gitlab> <metric_namespace> <metric_name>"
	exit 1
fi

. /etc/environment
GITLAB_API_TOKEN="$(cat /etc/gitlab/gitlab_root_api_token)"
export GITLAB_API_TOKEN
export http_proxy
export https_proxy
export no_proxy
export GIT_SSH_COMMAND='ssh -i /etc/login.gov/keys/id_ecdsa.identity-devops.deploy -o IdentitiesOnly=yes -o StrictHostKeyChecking=no'

# get the latest and greatest 
if [ -d /root/identity-devops ] ; then
	cd /root/identity-devops
	git pull
else
	cd /root
	if git clone git@localhost:lg/identity-devops.git ; then
		echo "cloned from local repo"
	else
		git clone git@github.com:18F/identity-devops.git
	fi
fi

# This binary should have been built by chef already
/etc/login.gov/repos/identity-devops/bin/users/users --fqdn="$1" --file=/root/identity-devops/terraform/master/global/users.yaml && aws cloudwatch put-metric-data --namespace "$2" --metric-name "$3" --value 1

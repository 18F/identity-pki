#!/bin/bash

set -euo pipefail

if [ -z "$2" ] ; then
  echo "usage:  $0"
  exit 1
fi

# shellcheck source=/dev/null
. /etc/environment
export http_proxy
export https_proxy
export no_proxy
export GIT_SSH_COMMAND='ssh -i /etc/login.gov/keys/id_ecdsa.identity-devops.deploy -o IdentitiesOnly=yes -o StrictHostKeyChecking=no'
export GEM_PATH='/etc/login.gov/repos/identity-devops/.bundle/ruby/3.3.0'
export AWS_DEFAULT_REGION='us-west-2'

# get the latest and greatest
if [ -d /usersync/identity-devops ] ; then
  cd /usersync/identity-devops
  git pull
else
  cd /usersync
  git clone git@github.com:18F/identity-devops.git
fi

/etc/login.gov/repos/identity-devops/bin/data-warehouse/users/redshift_sync.rb && aws cloudwatch put-metric-data --namespace "$1" --metric-name "$2" --value 1

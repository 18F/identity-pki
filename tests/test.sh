#!/bin/sh
#
# This script sets up the environment variables so that terraform and
# the tests can know how to run and what to test.
#

if [ -z "$1" ] || [ -z "$2" ] ; then
	echo "usage:   $0 <env_name> <idp_hostname>"
	echo "example: $0 tspencer secure.tspencer.foo.gov"
	exit 1
fi

export ENV_NAME="$1"
export IDP_HOSTNAME="$2"
export REGION="us-west-2"

go test -v -timeout 30m -run TestElkRecycle
#go test -v -timeout 30m


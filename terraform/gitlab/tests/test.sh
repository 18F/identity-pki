#!/bin/sh
#
# This script sets up the environment variables so that terraform and
# the tests can know how to run and what to test.
#

if [ -z "$1" ] || [ -z "$2" ]; then
	echo "usage:   $0 <gitlab_env_name> <domain>"
	echo "example: $0 bravo gitlab.foo.gov"
	exit 1
fi

export ENV_NAME="$1"; shift
export REGION=${REGION:="us-west-2"}
export DOMAIN="$2"; shift

cd "$(dirname "$0")"
go test -v -timeout 60m "$@"

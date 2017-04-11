#!/bin/bash
#
# Currently, our automation depends on a number of environment variables to
# configure terraform.  See
# https://www.terraform.io/docs/configuration/variables.html#environment-variables.
#
# There are some variables that are the same across each run, but some user
# specific configuration that's mixed in.  This script is an attempt to factor
# out and check for some of that configuration.
#
# Do not source this directly, only source it from another script that depends
# on this environment configuration, because it does some error checking and
# may exit your shell.
# See: https://github.com/18F/identity-devops/pull/252

# Check for empty even with "set -u" on http://stackoverflow.com/a/16753536
if [ -z "${GSA_FULLNAME:=}" -o -z "${GSA_EMAIL:=}" ] ; then
    echo "Must set GSA_FULLNAME and GSA_EMAIL in your environment"
    echo "GSA_FULLNAME is \"Firstname Lastname\" separated by a space"
    exit 1
fi

if [ -z "${AWS_ACCESS_KEY_ID:=}" -o -z "${AWS_SECRET_ACCESS_KEY:=}" ] ; then
    echo "Must set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY in your environment"
    exit 1
fi

if [ $# -ne 3 ] ; then
    echo "Usage: $0 <environment_name> <username> <env_file>"
    echo "  Loads <env_file> with the given arguments, but does some error"
    echo "  checking.  Run to make sure you have everything set before you"
    echo "  source because it may exit, or only source it in another script."
    exit 1
fi

export TF_VAR_env_name=$1
GSA_USERNAME=$2
ENV_FILE=$3

. $ENV_FILE

env

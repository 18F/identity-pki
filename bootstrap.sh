#!/bin/bash
# Use this script to create a new environment in AWS.

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 2 ] ; then
	echo "Usage: $0 <environment name> <username>"
	exit 1
fi

ENVIRONMENT=$1
GSA_USERNAME=$2

echo "This script will create the $ENVIRONMENT environment."
echo "If that environment already exists, this script may cause issues."
read -p "Are you sure you want to continue? " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]
then
	exit 1
fi

echo "BOOTSTRAP: Loading environment variables...."
. bin/load-env.sh $ENVIRONMENT $GSA_USERNAME env/env.sh

echo "BOOTSTRAP: Checking for required files that currently cannot be retrieved automatically...."
./bin/check-required-files.sh $ENVIRONMENT

echo "BOOTSTRAP: Setting client key placeholder to make terraform happy on first run...."
echo "    The chef terraform will overwrite this."
if [ ! -e $TF_VAR_chef_id_key_path ]; then
    openssl rand -base64 2048 | tr -d '\r\n' > $TF_VAR_chef_id_key_path
fi

echo "BOOTSTRAP: Setting databag key placeholder to make terraform happy on first run...."
echo "    The chef initial setup will overwrite this."
if [ ! -e $DATABAG_KEY_PATH ]; then
    openssl rand -base64 2048 | tr -d '\r\n' > $DATABAG_KEY_PATH
fi

echo "BOOTSTRAP: Running first terraform run to get the initial chef and jumphost instances...."
set +e # This is expected to fail the first run on missing databags
./deploy $ENVIRONMENT $GSA_USERNAME terraform-app apply
set -e

echo "BOOTSTRAP: Running initial bootstrap configuration of chef server...."
./bin/chef-configuration-first-run.sh $GSA_USERNAME $ENVIRONMENT

echo "BOOTSTRAP: Running final terraform run to complete environment setup...."
./deploy $ENVIRONMENT $GSA_USERNAME terraform-app apply

echo "The following steps don't work yet without manual pre-setup."
echo "See https://github.com/18F/identity-devops/wiki/Letsencrypt-Certificates"

echo "BOOTSTRAP: Setting up knife on the jumphost for your user...."
echo "./bin/setup-knife.sh $GSA_USERNAME $ENVIRONMENT ubuntu@jumphost.$ENVIRONMENT.login.gov"

echo "BOOTSTRAP: Running chef on all nodes...."
echo "ssh ubuntu@jumphost.$ENVIRONMENT.login.gov knife ssh 'name:*' 'sudo chef-client'"

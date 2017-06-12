#!/bin/bash
# Use this script to create a new environment in AWS.

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

exit_with_usage() {
    echo "Usage: $0 <environment_name> <username> <plan/apply/force-apply>"
    echo "   Creates a new <environment_name> environment in AWS."
    echo "   Pass in \"plan\" as the third argument to do a dry run."
    echo "   <username> should be the username of the first chef user that"
    echo "   you want to create.  Terraform uses this to install chef-clients."
    exit 1
}

if [ $# -ne 3 ] ; then
    exit_with_usage
fi

ENVIRONMENT=$1
GSA_USERNAME=$2
TF_CMD=$3

if [[ $TF_CMD = "plan" ]]; then
    echo "Doing terraform plan of the $ENVIRONMENT environment."
elif [[ $TF_CMD = "apply" ]]; then
    echo "This script will create the $ENVIRONMENT environment."
    echo "If that environment already exists, this script may cause issues."
    read -p "Are you sure you want to continue? (only \"yes\" will be accepted): "
    echo
    if [[ ! $REPLY = "yes" ]]; then
        exit 1
    fi
elif [[ $TF_CMD = "force-apply" ]]; then
    echo "BOOTSTRAP: Doing force-apply safety check...."
    if [[ "$ENVIRONMENT" == "prod" ||
        "$ENVIRONMENT" == "staging" ||
        "$ENVIRONMENT" == "int" ||
        "$ENVIRONMENT" == "dm" ||
        "$ENVIRONMENT" == "qa" ||
        "$ENVIRONMENT" == "pt" ||
        "$ENVIRONMENT" == "dev" ]]; then
        echo "ERROR: force-apply is dangerous and cannot be used on the $ENVIRONMENT environment!"
        exit 1
    fi
    echo "WARNING: Doing forced terraform apply of the $ENVIRONMENT environment."
    TF_CMD="apply"
else
    exit_with_usage
fi

echo "BOOTSTRAP: Loading environment variables...."
. bin/load-env.sh "$ENVIRONMENT" "$GSA_USERNAME"

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
./deploy $ENVIRONMENT $GSA_USERNAME terraform-app $TF_CMD
set -e

if [[ $TF_CMD = "plan" ]]; then
    echo "Stopping bootstrap before destructive changes as the \"plan\" option was specified."
    exit
fi

echo "BOOTSTRAP: Running initial bootstrap configuration of chef server...."
./bin/chef-configuration-first-run.sh "$GSA_USERNAME" "$ENVIRONMENT" "$TF_VAR_chef_home"

echo "BOOTSTRAP: Running final terraform run to complete environment setup...."
./deploy $ENVIRONMENT $GSA_USERNAME terraform-app apply

echo "The following steps don't work yet without manual pre-setup."
echo "See https://github.com/18F/identity-devops/wiki/Letsencrypt-Certificates"

echo "BOOTSTRAP: Setting up knife on the jumphost for your user...."
echo "./bin/setup-knife.sh $GSA_USERNAME $ENVIRONMENT ubuntu@jumphost.$ENVIRONMENT.login.gov"

echo "BOOTSTRAP: Running chef on all nodes...."
echo "ssh ubuntu@jumphost.$ENVIRONMENT.login.gov knife ssh 'name:*' 'sudo chef-client'"

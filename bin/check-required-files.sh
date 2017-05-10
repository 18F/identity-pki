#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 1 ] ; then
    echo "Usage: $0 <environment name>"
    exit 1
fi

echo "Checking for required files for environment $1"

cat <<EOF

#################################################################################
# We have some secrets that we currently share manually for each environment.   #
#                                                                               #
# See: https://github.com/18F/identity-private/issues/1806 and                  #
# https://github.com/18F/identity-private/issues/863 for more context.          #
#                                                                               #
# This script will check for most shared secrets.  The only thing that it does  #
# not check for is that you have the bootstrap key for the \"ubuntu\" user.     #
#                                                                               #
# See: https://github.com/18F/identity-private/issues/1730 for more information #
# about this shared key.  You'll probably need to get it from someone on the    #
# team.                                                                         #
#                                                                               #
# This should be run with the environment used to terraform.                    #
#################################################################################

EOF

echo "CHECK: Required Nessus package..."
NESSUS_DOWNLOAD_URL="http://downloads.nessus.org/nessus3dl.php?file=Nessus-6.10.0-ubuntu1110_amd64.deb&licence_accept=yes&t=c89a8794496b26a61d8a09e9af89cb97"
NESSUS_FILENAME="Nessus-6.10.0-ubuntu1110_amd64.deb"
echo "Checking if Nessus Manager exists at $NESSUS_FILENAME"
if [ ! -e $NESSUS_FILENAME ]; then
    echo "Downloading Nessus Manager to $NESSUS_FILENAME"
    curl -L $NESSUS_DOWNLOAD_URL -o $NESSUS_FILENAME
fi

echo "CHECK: Required jenkins key: $TF_VAR_git_deploy_key_path"
if [ ! -e $TF_VAR_git_deploy_key_path ]; then
    echo "ERROR: Missing jenkins key.  Get this from one of the team members"
    echo "    This step should go away with https://github.com/18F/identity-private/issues/863"
    echo "    See: https://github.com/18F/identity-private/issues/1769#issuecomment-290834999"
    exit 1
fi

echo "CHECK: Required chef databags..."
USERS_DATABAGS="kitchen/data_bags/users/"
if [ ! -e  $USERS_DATABAGS ]; then
    echo "ERROR: No config databag at: $USERS_DATABAGS"
    echo "    You need at least one user account to configure"
    echo "    in chef.  See https://github.com/18F/identity-devops/wiki/Chef-Databags"
    exit 1
fi
CONFIG_DATABAG="kitchen/data_bags/config/${1}.json"
if [ ! -e  $CONFIG_DATABAG ]; then
    echo "ERROR: No user databags at: $CONFIG_DATABAG"
    echo "    You need to have a config databag for chef."
    echo "    See https://github.com/18F/identity-devops/wiki/Chef-Databags"
    exit 1
fi

echo "CHECK: Required environment config..."
CHEF_ENVIRONMENT_CONFIG="kitchen/environments/${1}.json"
if [ ! -e  $CHEF_ENVIRONMENT_CONFIG ]; then
    echo "ERROR: No configuration found at: $CHEF_ENVIRONMENT_CONFIG"
    echo "    You need to create and push a configuration to"
    echo "    the branch you are deploying from.  Copy this from"
    echo "    an existing configuration in that directory."
    echo "    See: https://github.com/18F/identity-private/issues/1769#issuecomment-291249605"
    exit 1
fi

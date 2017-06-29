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

# shellcheck disable=2154
echo "CHECK: Required jenkins key: $TF_VAR_git_deploy_key_path"
if [ ! -e "$TF_VAR_git_deploy_key_path" ]; then
    cat 1>&2 <<EOF

ERROR: Missing jenkins key at $TF_VAR_git_deploy_key_path.
    This key is what Jenkins uses to download from Github.  If you aren't
    working with Jenkins, any private key will let the deploy continue,
    otherwise ask someone on the team for the key that has Github access.

    This step should go away with https://github.com/18F/identity-private/issues/863
    See: https://github.com/18F/identity-private/issues/1769#issuecomment-290834999

EOF
    exit 1
fi

echo "CHECK: Required chef databags..."
USERS_DATABAGS="kitchen/data_bags/users"
NUM_USERS=$(find "$USERS_DATABAGS" -name '*.json' -type f | wc -l)
if [[ $NUM_USERS -eq 0 ]]; then
    echo "ERROR: No user databags found at: $USERS_DATABAGS/*.json"
    echo "    You need at least one user account to configure"
    echo "    in chef.  See https://github.com/18F/identity-devops/wiki/Chef-Databags"
    echo "    You can create one with:  bin/make-user-databag.sh \$USERNAME"
    exit 1
fi
CONFIG_DATABAG="kitchen/data_bags/config/${1}.json"
if [ ! -e "$CONFIG_DATABAG" ]; then
    echo "ERROR: No env config databag at: $CONFIG_DATABAG"
    echo "    You need to have a config databag for chef."
    echo "    See https://github.com/18F/identity-devops/wiki/Chef-Databags"
    echo "    You can create one with:  bin/make-config-databag.sh \$ENVIRONMENT"
    exit 1
fi

echo "CHECK: Required environment config..."
CHEF_ENVIRONMENT_CONFIG="kitchen/environments/${1}.json"
if [ ! -e "$CHEF_ENVIRONMENT_CONFIG" ]; then
    echo "ERROR: No configuration found at: $CHEF_ENVIRONMENT_CONFIG"
    echo "    You need to create and push a configuration to"
    echo "    the branch you are deploying from.  Copy this from"
    echo "    an existing configuration in that directory."
    echo "    See: https://github.com/18F/identity-private/issues/1769#issuecomment-291249605"
    exit 1
fi

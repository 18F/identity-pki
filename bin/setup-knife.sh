#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 4 ] ; then
    cat <<EOF
usage:  $0 <username> <environment> <remote_host> <chef_config_dir>
  Sets up knife for <username> and <environment> on <remote_host>.

  <remote_host> is passed directly to ssh so include the username.

  <chef_config_dir> is the local directory with your chef secrets.

  By default, the environment setup will use ~/.chef, so if you are
  unsure what directory to use that is likely the correct place.

EOF
    exit 1
fi

USERNAME=$1
ENVIRONMENT=$2
REMOTE_SSH=$3
CHEF_CONFIG_DIR=$4

echo "Creating knife-$ENVIRONMENT.rb configuration file for $REMOTE_SSH..."
REMOTE_HOME="$(ssh -o StrictHostKeyChecking=no "$REMOTE_SSH" 'echo "$HOME"')"
REMOTE_CHEF_HOME="$REMOTE_HOME/.chef/"
cat <<EOF | tee "$CHEF_CONFIG_DIR/knife-$ENVIRONMENT.rb"
log_level                :info
log_location             STDOUT
node_name                '$USERNAME'
client_key               '$REMOTE_CHEF_HOME/$USERNAME-$ENVIRONMENT.pem'
validation_client_name   '$ENVIRONMENT-login-dev-validator'
validation_key           '$REMOTE_CHEF_HOME/$ENVIRONMENT-login-dev-validator.pem'
chef_server_url          'https://chef.login.gov.internal/organizations/login-dev'
syntax_check_cache_path  '$REMOTE_CHEF_HOME/syntax_check_cache'
cookbook_path            [ './kitchen/cookbooks' ]
ssl_verify_mode          :verify_none
knife[:secret_file] =    '$REMOTE_CHEF_HOME/$ENVIRONMENT-databag.key'
EOF

echo "Uploading required files for knife..."
# shellcheck disable=SC2029
ssh -o StrictHostKeyChecking=no "$REMOTE_SSH" "mkdir -p \"$REMOTE_CHEF_HOME\""
scp -o StrictHostKeyChecking=no "$CHEF_CONFIG_DIR/$USERNAME-$ENVIRONMENT.pem" "$REMOTE_SSH:$REMOTE_CHEF_HOME/$USERNAME-$ENVIRONMENT.pem"
scp -o StrictHostKeyChecking=no "$CHEF_CONFIG_DIR/$ENVIRONMENT-login-dev-validator.pem" "$REMOTE_SSH:$REMOTE_CHEF_HOME/$ENVIRONMENT-login-dev-validator.pem"
# XXX: Normally knife block makes knife.rb a symlink, but on the first run chef
# hasn't installed knife block yet, so this is the current workaround.
scp -o StrictHostKeyChecking=no "$CHEF_CONFIG_DIR/knife-$ENVIRONMENT.rb" "$REMOTE_SSH:$REMOTE_CHEF_HOME/knife.rb"

echo "Checking for config databag secret key..."
if [ -e "$CHEF_CONFIG_DIR/$ENVIRONMENT-databag.key" ]; then
    echo "Uploading key: $CHEF_CONFIG_DIR/$ENVIRONMENT-databag.key"
    scp -o StrictHostKeyChecking=no "$CHEF_CONFIG_DIR/$ENVIRONMENT-databag.key" "$REMOTE_SSH:$REMOTE_CHEF_HOME/$ENVIRONMENT-databag.key"
fi

echo "Finished setting up knife!"

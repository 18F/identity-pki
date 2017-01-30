#!/bin/sh
#
# This script creates a client on the specified chef-server
#

if [ -z "$1" -o -z "$TF_VAR_chef_id" -o -z "$TF_VAR_chef_id_key_path" -o -z "$VALIDATION_KEY_PATH" -o -z "$TF_VAR_chef_info" ] ; then
	echo "usage:  $0 <hostname/ip>"
	echo "example: $0 1.2.3.4"
	echo "This script expects the environment to be set up that you would normally use for terraforming"
	exit 1
end

echo "ssh -o StrictHostKeyChecking=no $1 sudo chef-server-ctl user-create $TF_VAR_chef_id $TF_VAR_chef_info > $TF_VAR_chef_id_key_path"
echo "ssh -o StrictHostKeyChecking=no $1 sudo chef-server-ctl org-user-add login-dev $TF_VAR_chef_id --admin"
echo "ssh -o StrictHostKeyChecking=no $1 sudo cat /root/login-dev-validator.pem > $VALIDATION_KEY_PATH"

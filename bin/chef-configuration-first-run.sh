#!/bin/bash
#
# This script creates a client on the specified chef-server and saves important keys to the local chef directory.

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 2 ] ; then
        echo "usage:  $0 <username> <environment name>"
        exit 1
fi

USERNAME=$1
ENVIRONMENT=$2

run() {
    echo >&2 "+ $*"
    "$@"
}

echo "Getting the public IP of the jumphost instance..."
JUMPHOST_PUBLIC_IP="$(run aws ec2 describe-instances --region us-west-2 \
                         --filter "Name=tag:Name,Values=login-jumphost-$ENVIRONMENT" \
                                  "Name=instance-state-name,Values=running" \
                         --output text \
                         --query 'Reservations[*].Instances[*].PublicIpAddress')"

if [ -z "$JUMPHOST_PUBLIC_IP" ]; then
    echo "ERROR: Could not find jumphost for environment: $ENVIRONMENT"
    exit 1
fi
echo "Found jumphost: $JUMPHOST_PUBLIC_IP"

echo "Setting up knife on the jumphost..."
$(dirname $0)/setup-knife.sh $USERNAME $ENVIRONMENT ubuntu@$JUMPHOST_PUBLIC_IP

echo "Uploading the chef config databag..."
scp -o StrictHostKeyChecking=no kitchen/data_bags/config/$ENVIRONMENT.json ubuntu@$JUMPHOST_PUBLIC_IP:~

echo "Adding the encrypted config databag to chef..."
ssh -o StrictHostKeyChecking=no ubuntu@$JUMPHOST_PUBLIC_IP "openssl rand -base64 2048 | tr -d '\r\n' > ~/.chef/$ENVIRONMENT-databag.key"
ssh -o StrictHostKeyChecking=no ubuntu@$JUMPHOST_PUBLIC_IP "knife data bag create config --secret-file ~/.chef/$ENVIRONMENT-databag.key"
ssh -o StrictHostKeyChecking=no ubuntu@$JUMPHOST_PUBLIC_IP "knife data bag from file config ./$ENVIRONMENT.json --secret-file ~/.chef/$ENVIRONMENT-databag.key"

echo "Downloading secret key for encrypted databag..."
scp -o StrictHostKeyChecking=no ubuntu@$JUMPHOST_PUBLIC_IP:~/.chef/$ENVIRONMENT-databag.key ~/.chef/$ENVIRONMENT-databag.key

echo "Creating the unencrypted users databag to add your users(and other in identity-devops) to the chef-server..."
ssh -o StrictHostKeyChecking=no ubuntu@$JUMPHOST_PUBLIC_IP "knife data bag create users"

echo "Copying local user databags from kitchen/data_bags/users to jumphost..."
scp -o StrictHostKeyChecking=no -r kitchen/data_bags/users ubuntu@$JUMPHOST_PUBLIC_IP:users
ssh -o StrictHostKeyChecking=no ubuntu@$JUMPHOST_PUBLIC_IP 'for user in users/*.json; do knife data bag from file users $user; done'

echo "Verifying user: $USERNAME has been uploaded to the chef server"
ssh -o StrictHostKeyChecking=no ubuntu@$JUMPHOST_PUBLIC_IP "knife data bag show users $USERNAME -F json"

echo "Verifying configuration has been uploaded to the chef server and is readable"
ssh -o StrictHostKeyChecking=no ubuntu@$JUMPHOST_PUBLIC_IP "knife data bag show config app -F json"

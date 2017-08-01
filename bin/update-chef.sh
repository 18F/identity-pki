#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 2 ] ; then
    cat <<EOF
usage:  $0 <environment> <gitref>

  Updates the state of the roles, <environment> environment, and cookbooks on
  the chef server to <gitref>.

  You should first run bin/setup-knife.sh in identity-devops on this server to
  make sure knife is setup properly, or have it set up properly using other
  means because this script will use that configuration.

EOF
    exit 1
fi

ENVIRONMENT=$1
GITREF=$2

run() {
    echo >&2 "+ $*"
    "$@"
}

if [ -z "${UPDATE_CHEF_LOCAL-}" ]; then
    if [[ $(hostname -f) != *.$ENVIRONMENT.login.gov* ]]; then
        cat >&2 <<EOM
Warning: local hostname $(hostname -f) doesn't look like a server!
This script is meant to be run somewhere that knife is set up.
(Set UPDATE_CHEF_LOCAL=1 to suppress this warning.)
Did you mean to run remote-update-chef.sh ?
EOM
        read -r -p "Press enter to continue anyway... "
    fi
fi

echo "Cloning identity-devops and checking out gitref: $GITREF..."
run rm -rf identity-devops-berks-uploader-tmp
run git clone git@github.com:18F/identity-devops.git identity-devops-berks-uploader-tmp
echo "+ cd identity-devops-berks-uploader-tmp"
pushd identity-devops-berks-uploader-tmp
run git checkout "$GITREF"

echo "Installing necessary gems..."
run bundle install

echo "Using Berkshelf to sync cookbooks..."
run berks
run berks upload --force --ssl-verify=false

echo "Using knife to sync environment configuration..."
for i in kitchen/environments/* ; do
	run knife environment from file "$i"
done

echo "Using knife to sync role configuration..."
for i in kitchen/roles/* ; do
	run knife role from file "$i"
done

echo "Using Berkshelf to apply the environment..."
run berks apply "$ENVIRONMENT" --ssl-verify=false

echo "Cleaning up identity-devops clone..."
popd
run rm -rf identity-devops-berks-uploader-tmp

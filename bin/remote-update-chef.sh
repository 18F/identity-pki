#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 3 ] ; then
    cat <<EOF
usage:  $0 <environment> <jumphost> <gitref>
  
  Updates the state of the roles, the <environment> environment configuration,
  and cookbooks on the chef server to <gitref> from <jumphost>.

  You should first run bin/setup-knife.sh in identity-devops to make sure knife
  is setup on the jumphost as this script will use the chef configuration
  already on <jumphost> rather than reconfiguring.

EOF
    exit 1
fi

ENVIRONMENT=$1
JUMPHOST=$2
GITREF=$3

run() {
    echo >&2 "+ $*"
    "$@"
}

run scp -o StrictHostKeyChecking=no bin/update-chef.sh "$JUMPHOST:~"
# shellcheck disable=SC2029
run ssh -o StrictHostKeyChecking=no -A -M "$JUMPHOST" "./update-chef.sh $ENVIRONMENT $GITREF"

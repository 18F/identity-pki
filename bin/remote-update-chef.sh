#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -lt 1 ] ; then
    cat <<EOF
usage:  $0 <environment> [<jumphost> [<gitref>]]

  Updates the state of the roles, the <environment> environment configuration,
  and cookbooks on the chef server to <gitref> from <jumphost>.

  You should first run bin/setup-knife.sh in identity-devops to make sure knife
  is setup on the jumphost as this script will use the chef configuration
  already on <jumphost> rather than reconfiguring.

  jumphost: defaults to jumphost.ENVIRONMENT.login.gov
  gitref: defaults to HEAD, the current latest revision

EOF
    exit 1
fi

run() {
    echo >&2 "+ $*"
    "$@"
}

ENVIRONMENT=$1
JUMPHOST=${2-"jumphost.$ENVIRONMENT.login.gov"}
GITREF=${3-"$(run git rev-parse HEAD)"}

echo >&2 "Rolling out $GITREF to $JUMPHOST in $ENVIRONMENT"

run scp -o StrictHostKeyChecking=no bin/update-chef.sh "$JUMPHOST:~"
# shellcheck disable=SC2029
run ssh -o StrictHostKeyChecking=no -A -M "$JUMPHOST" "./update-chef.sh $ENVIRONMENT $GITREF"

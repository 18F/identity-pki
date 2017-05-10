#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 1 ] ; then
    echo "Usage: $0 <environment_name>"
    echo "  Creates the chef config databag for <environment_name>"
    exit 1
fi

ENVIRONMENT=$1

cat <<EOF

Creating chef config data bag for $ENVIRONMENT

You still have to edit this manually if https://github.com/18F/identity-private/issues/1824 is still
open because we share many infrastructure secrets out of band.  See
https://github.com/18F/identity-private/wiki/Operations:-Chef-Databags

EOF
mkdir -p kitchen/data_bags/config/
if [ -e kitchen/data_bags/config/$ENVIRONMENT.json ]; then
    echo "File: kitchen/data_bags/config/$ENVIRONMENT.json already exists!  Not creating."
    exit 1
fi
sed "s/XXXenv/$ENVIRONMENT/g" template_config_dbag.json > kitchen/data_bags/config/$ENVIRONMENT.json
echo "Successfully created: kitchen/data_bags/config/$ENVIRONMENT.json"

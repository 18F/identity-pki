#!/bin/sh

## Example release:
## Tuesday
# bin/cut-release
# export DEPLOY_RELEASE=v200
# bin/release.sh clean
# bin/release.sh int
# bin/release.sh pt
# bin/release.sh pt2
## Wednesday
# bin/release.sh staging
# bin/release.sh dm
# bin/release.sh non-app-non-prod
## Thursday
# bin/release.sh prod
# bin/release.sh non-app-prod

WRAPPER=$0 make -f "$(dirname "$0")/release.mk" "$@"

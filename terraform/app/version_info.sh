#!/bin/bash
#
# This script finds the version info out for the identity-devops
# and identity-devops-private repos.
#
# If we are running in a codebuild context, use the variables
# set by be pipeline.
#
set -e

if [ -z "$CODEBUILD_SRC_DIR" ] ; then
	if [ ! -d "$1" ] || [ ! -d "$2" ] ; then
		echo "$1 or $2 are not directories"
		exit 1
	fi

	cd "$1"
	IDCOMMIT=$(git rev-parse HEAD)
	IDBRANCH=$(git rev-parse --abbrev-ref HEAD)

	cd "$2"
	IDPRIVATECOMMIT=$(git rev-parse HEAD)
	IDPRIVATEBRANCH=$(git rev-parse --abbrev-ref HEAD)
else
	if [ -z "$IDCOMMIT" ] || [ -z "$IDBRANCH" ] || [ -z "$IDPRIVATECOMMIT" ] || [ -z "$IDPRIVATEBRANCH" ] ; then
		echo "pipeline variables are not being set"
		exit 2
	fi
fi

# emit json which terraform can parse
cat <<EOF
{
	"identity-devops-commit": "$IDCOMMIT",
	"identity-devops-branch": "$IDBRANCH",
	"identity-devops-private-commit": "$IDPRIVATECOMMIT",
	"identity-devops-private-branch": "$IDPRIVATEBRANCH"
}
EOF

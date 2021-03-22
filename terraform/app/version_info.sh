#!/bin/bash
#
# This script finds the version info out for the identity-devops
# and identity-devops-private repos.
#
# If we are running in a codebuild context, use the locations set
# by codebuild (CODEBUILD_SRC_DIR and
# CODEBUILD_SRC_DIR_identity_devops_private).
#
set -e

IDREPOPATH="${CODEBUILD_SRC_DIR:-$1}"
IDPRIVATEREPOPATH="${CODEBUILD_SRC_DIR_identity_devops_private:-$2}"

cd "$IDREPOPATH"
IDCOMMIT=$(git rev-parse HEAD)
IDBRANCH=$(git rev-parse --abbrev-ref HEAD)

cd "$IDPRIVATEREPOPATH"
IDPRIVATECOMMIT=$(git rev-parse HEAD)
IDPRIVATEBRANCH=$(git rev-parse --abbrev-ref HEAD)

# emit json which terraform can parse
cat <<EOF
{
	"identity-devops-commit": "$IDCOMMIT",
	"identity-devops-branch": "$IDBRANCH",
	"identity-devops-private-commit": "$IDPRIVATECOMMIT",
	"identity-devops-private-branch": "$IDPRIVATEBRANCH"
}
EOF

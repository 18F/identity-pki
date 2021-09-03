#!/bin/bash

set -euo pipefail

. "$(dirname "$0")/lib/common.sh"

man_page() {
  cat >&2 << EOM

Creates a ZIP file (a la the now-deprecated terraform-bundle tool)
containing the Terraform binary (compiled from the repo) and the
plugins in the repo-wide lockfile, then copies them up into the
auto-tf bucket for use by CodeBuild in doing its auto-tf stuff.
Requires docker (installed+running) and login-tooling access.

- Invokes aws-vault itself, so you don't have to!
- Designed to be run without arguments.
EOM
usage
}

usage() {
  cat >&2 << EOM

Usage: ${0}
Options:

  -v : TF_VERSION
  -k : Keep /tmp/terraform-bundle dir after uploading
  -h : Display help

EOM
}

verify_root_repo
which docker >/dev/null || raise "Docker binary not found"

TF_VERSION=$(get_terraform_version)
KEEP_BUILD_DIR=0

while getopts v:kh opt
do
  case $opt in
    v) TF_VERSION="v${OPTARG}" ;;
    k) KEEP_BUILD_DIR=1        ;;
    h) man_page && exit 0      ;;
    *) raise 'Invalid option'  ;;
  esac
done
shift $((OPTIND-1))

GOLANG_VERSION=$(curl -s \
  "https://raw.githubusercontent.com/hashicorp/terraform/${TF_VERSION}/.go-version")
[[ ${GOLANG_VERSION} == "404: Not Found" ]] && raise "Terraform ${TF_VERSION} not available"

AV_PROFILE=$(get_profile_name $(get_acct_num tooling))
TF_ZIP="terraform_${TF_VERSION}-bundle$(date -j +%Y%m%d%H)_linux_amd64.zip"
echo_green "Using Terraform ${TF_VERSION} / golang ${GOLANG_VERSION}"

rm -rf /tmp/terraform-bundle.$$
mkdir /tmp/terraform-bundle.$$

TF_LOCKFILE="${GIT_DIR}/terraform/tooling/tooling/.terraform.lock.hcl"
[ -f ${TF_LOCKFILE} ] && rm ${TF_LOCKFILE} # use repo lockfile only
$(dirname "$0")/td -e tooling -d tooling -v mirror \
  -platform=linux_amd64 /tmp/terraform-bundle.$$/plugins

# uncomment once https://github.com/docker-library/golang/issues/362 is resolved
# export DOCKER_CONTENT_TRUST=1
cd /tmp/terraform-bundle.$$
run docker pull golang:${GOLANG_VERSION}
docker run --rm -i -v "$PWD":/terraform-bundle golang:${GOLANG_VERSION} <<EOF
# Install terraform-bundle
cd /tmp
git clone --depth 1 --branch ${TF_VERSION} https://github.com/hashicorp/terraform
cd terraform/
go install .
cp \$(go env GOPATH)/bin/terraform /terraform-bundle
EOF

zip -r ${TF_ZIP} plugins terraform
cd -
ave aws s3 cp /tmp/terraform-bundle.$$/${TF_ZIP} "s3://auto-tf-bucket-$(get_acct_num tooling)/"
[[ ${KEEP_BUILD_DIR} == 0 ]] && rm -rf /tmp/terraform-bundle.$$

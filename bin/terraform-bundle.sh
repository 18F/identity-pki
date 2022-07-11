#!/bin/bash

#### ZIP up a Terraform binary, and provider plugins, for auto-tf to use ####

set -euo pipefail

. "$(dirname "$0")/lib/common.sh"

help_me() {
  cat >&2 << EOM

Creates a ZIP file (a la the now-deprecated terraform-bundle tool) containing the
Terraform binary (compiled from the repo) and the plugins in the repo-wide lockfile,
then copies them up into the auto-tf bucket for use by CodeBuild in doing its
auto-tf stuff.

- Requires login-tooling access; best run via aws-vault.
- Designed to be run without arguments.
EOM
  usage
  exit 0
}

usage() {
  cat >&2 << EOM

Usage: ${0} [-v VERSION|-k|-h]

Flags:
  -v VERSION : Manually specify version of Terraform to use
  -k         : Keep /tmp/terraform-bundle dir after uploading
  -h         : Display help

EOM
}

verify_root_repo

TF_VERSION=$(get_terraform_version)
REAL_TF_VERSION="${TF_VERSION:1}"
KEEP_BUILD_DIR=0
TF_ZIP="terraform_${TF_VERSION}-bundle$(date -j +%Y%m%d%H)_linux_amd64.zip"

while getopts v:kh opt
do
  case $opt in
    v) TF_VERSION="v${OPTARG}" ;;
    k) KEEP_BUILD_DIR=1        ;;
    h) help_me                 ;;
    *) usage && exit 1         ;;
  esac
done
shift $((OPTIND-1))

if [[ ! $(env | grep 'AWS_VAULT=') ]] || [[ ! "${AWS_VAULT}" =~ 'tooling' ]] ; then
  raise 'Must be run with a login-tooling AWS profile/assumed role!'
fi

ACCT_NUMBER=$(aws sts get-caller-identity --query "Account" --output text)

echo_green "Using Terraform ${TF_VERSION}"

rm -rf /tmp/terraform-bundle.$$
mkdir /tmp/terraform-bundle.$$

# prepare to install provider plugins here
cp versions.tf versions.tf.old* /tmp/terraform-bundle.$$/

# install current provider plugins
cd /tmp/terraform-bundle.$$
terraform init
terraform providers mirror -platform=linux_amd64 ./plugins
rm -rf .terraform .terraform.lock.hcl

# install old provider plugins
cd /tmp/terraform-bundle.$$
for i in versions.tf.old* ; do
  echo_green "working on $i"
  mv "$i" versions.tf
  terraform init
  terraform providers mirror -platform=linux_amd64 ./plugins
  rm -rf .terraform .terraform.lock.hcl
done

# download terraform binary
curl -s "https://releases.hashicorp.com/terraform/${REAL_TF_VERSION}/terraform_${REAL_TF_VERSION}_linux_amd64.zip" > /tmp/terraform-bundle.$$/tf.zip
unzip tf.zip
rm tf.zip

# pack it up and ship it off
zip -r "${TF_ZIP}" plugins terraform
aws s3 cp /tmp/terraform-bundle.$$/"${TF_ZIP}" "s3://auto-tf-bucket-${ACCT_NUMBER}/"
[[ ${KEEP_BUILD_DIR} == 0 ]] && rm -rf /tmp/terraform-bundle.$$

#!/bin/sh
#
# This script creates a terraform bundle with the proper version of terraform
# and the plugins we need and copy them up into the auto-tf bucket for use
# by CodeBuild in doing it's auto-tf stuff.
#
# The versions of all these things were just gathered by searching for
# required_providers in the identity-devops repo.
#
# This script requires a working docker setup so that it can get golang.
# It is meant to be run with aws-vault, like:
#    aws-vault exec tooling-admin -- bin/terraform-bundle.sh
#
set -e

TERRAFORM_VERSION="0.13.7"
GOLANG_VERSION="1.15"

rm -rf /tmp/terraform-bundle.$$
mkdir /tmp/terraform-bundle.$$
cd /tmp/terraform-bundle.$$

export DOCKER_CONTENT_TRUST=1
docker pull golang:$GOLANG_VERSION
docker run --rm -i -v "$PWD":/terraform-bundle golang:$GOLANG_VERSION <<EOF
# Install terraform-bundle
cd /tmp
curl -L "https://github.com/hashicorp/terraform/archive/v${TERRAFORM_VERSION}.tar.gz" > tf.tgz
tar zxpf tf.tgz
cd "terraform-${TERRAFORM_VERSION}"
go install .
go install ./tools/terraform-bundle

# configure terraform-bundle to download the proper versions of everything.
# This is used instead of the lockfile because the lockfile can only have one version of
# the plugin in it, and we need multiple versions bundled so that auto-tf can run against
# different branches that may not have the latest plugins yet.
cat <<EOFEOF > /tmp/terraform-bundle.hcl
terraform {
  version = "${TERRAFORM_VERSION}"
}

# Define which provider plugins are to be included
# NOTE:  You should only probably have 2-3 versions in these lists, since we want
#        to encourage people to get up to date, but we need to be able to handle
#        one version back at least so that auto-tf can still function even if the
#        branch it is pointing at is a bit older than main.
providers {
  aws = {
    versions = ["3.71.0", "3.70.0", "3.45.0"]
  }
  archive = {
    versions = ["2.2.0"]
  }
  external = {
    versions = ["2.2.0", "2.1.0"]
  }
  github = {
    versions = ["4.19.1", "4.13.0"]
  }
  null = {
    versions = ["3.1.0", "2.1.2"]
  }
  template = {
    versions = ["2.2.0", "2.1.2"]
  }
  newrelic = {
    source = "newrelic/newrelic"
    versions = ["2.35.0", "2.24.1", "2.21.1"]
  }
  kubectl = {
    source = "gavinbunney/kubectl"
    versions = ["1.11.1"]
  }
  helm = {
    versions = ["2.1.2"]
  }
  kubernetes = {
    versions = ["2.0.3"]
  }
  tls = {
    versions = ["3.1.0"]
  }
}
EOFEOF

# bundle it all up
cd /terraform-bundle
terraform-bundle package -os=linux -arch=amd64 /tmp/terraform-bundle.hcl
EOF

# copy the bundled terraform stuff up to the auto-tf bucket
ACCOUNT=$(aws sts get-caller-identity --output text --query 'Account')
echo
echo "uploading /tmp/terraform-bundle.$$/terraform_${TERRAFORM_VERSION}-bundle*_linux_amd64.zip"
aws s3 cp /tmp/terraform-bundle.$$/terraform_${TERRAFORM_VERSION}-bundle*_linux_amd64.zip "s3://auto-tf-bucket-$ACCOUNT/"

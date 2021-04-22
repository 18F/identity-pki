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

TERRAFORM_VERSION="0.13.5"
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

# configure terraform-bundle to download the proper versions of everything
cat <<EOFEOF > /tmp/terraform-bundle.hcl
terraform {
  version = "${TERRAFORM_VERSION}"
}

# Define which provider plugins are to be included
providers {
  aws = {
    versions = ["~> 3.11.0", "~> 3.27.0"]
  }
  archive = {
    versions = ["~> 1.3"]
  }
  external = {
    versions = ["~> 1.2.0"]
  }
  github = {
    versions = ["~> 2.9"]
  }
  null = {
    versions = ["~> 2.1.2"]
  }
  template = {
    versions = ["~> 2.1.2"]
  }
  newrelic = {
    source = "newrelic/newrelic"
    versions = ["2.21.1", "~> 2.21.0", "~> 2.8.0", "~> 2.1.2"]
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

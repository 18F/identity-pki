#!/bin/sh
#
# This script will sign an image using a specified key.
# It is meant to be run by devsecops people to approve an image.
#
# Keys are created using bin/create_image_signing_key.sh
#

if [ -z "$2" ] ; then
	echo "usage: $0 <keyname> <image>"
	echo "  where the keyname is the base name of the file that contains the KMS signing key in the common dir in the secrets bucket"
	echo "example: $0 prod_cosign XXX.dkr.ecr.us-west-2.amazonaws.com/tspencer/env_deploy:@sha256:SHA"
	exit 1
fi

if which cosign >/dev/null ; then
	true
else
	echo "cosign must be installed:  brew install cosign"
	exit 1
fi

# default to us-west-2 region
if [ -z "$AWS_REGION" ] ; then
	export AWS_REGION=us-west-2
fi

# get the account ID
AWS_ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)

# get the key ID
AWS_CMK_ID=$(aws s3 cp "s3://login-gov.secrets.${AWS_ACCOUNTID}-${AWS_REGION}/common/$1.keyid" -)

# Sign the image
cosign sign --tlog-upload=false --key "awskms:///${AWS_CMK_ID}" "$2"

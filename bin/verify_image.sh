#!/bin/sh
#
# This script will verify a cosign image signature.
# It is meant to be run by devsecops people to approve an image.
#
# Keys are created using terraform
#

if [ -z "$1" ] ; then
	echo "usage: $0 <image>"
	echo "example: $0 XXX.dkr.ecr.us-west-2.amazonaws.com/tspencer/env_deploy:@sha256:SHA"
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

# key id in every account with a signing key is set to this key
AWS_CMK_ID="alias/image_signing_cosign_signature_key"

# Sign the image
cosign verify --insecure-ignore-tlog=true --key "awskms:///${AWS_CMK_ID}" "$1"

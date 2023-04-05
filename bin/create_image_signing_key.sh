#!/bin/sh


if [ -z "$1" ] ; then
	echo "usage: $0 <keyname>"
	echo "  where the keyname is the name of the file that contains the KMS signing key in the common dir in the secrets bucket"
	echo "example: $0 prod_cosign"
	exit 1
fi

if which jq >/dev/null ; then
	true
else
	echo "jq must be installed:  brew install jq"
	exit 1
fi

# default to us-west-2 region
if [ -z "$AWS_REGION" ] ; then
	export AWS_REGION=us-west-2
fi

# get the account ID
AWS_ACCOUNTID=$(aws sts get-caller-identity --query Account --output text)



# create key
aws kms create-key --customer-master-key-spec RSA_4096 --key-usage SIGN_VERIFY --description "$1 Cosign Signature Key" > /tmp/keydata.json.$$
AWS_CMK_ID=$(cat /tmp/keydata.json.$$ | jq -r .KeyMetadata.KeyId)

# create file that has the key ID in it
echo "$AWS_CMK_ID" | aws s3 cp - "s3://login-gov.secrets.${AWS_ACCOUNTID}-${AWS_REGION}/common/$1.keyid"

# get the public key and store it next to the key ID
aws kms get-public-key --key-id "$AWS_CMK_ID" --output text --query PublicKey | base64 -d > /tmp/cosign.der.$$
openssl rsa -pubin -inform der -outform PEM -in /tmp/cosign.der.$$ -out /tmp/cosign.pub.$$
aws s3 cp /tmp/cosign.pub.$$ "s3://login-gov.secrets.${AWS_ACCOUNTID}-${AWS_REGION}/common/$1.pub"

# clean up
rm -f /tmp/keydata.json.$$ /tmp/cosign.der.$$ /tmp/cosign.pub.$$

#!/bin/bash
set -euo pipefail

run() {
    echo >&2 "+ $*"
    "$@"
}

usage() {
    cat >&2 << EOM
Usage: ${0} [-a ami_id] [-s sourceAccountId] [-r role]
Usage: ${0} [--ami ami_id] [--source_account account id for image] [--role role]
    -a|--ami,               ID of AMI to be copied.
    -s|--source_account,    Source account ID for image.
    -r|role,                Image role to copy (base or rails).
    -h|help,                Show this message.

By default, this will copy the most recently shared base ami from the sandbox account.
For example:
To copy the latest shared rails image from the sandbox account
${0} --role rails

To copy the latest shared base image from the sandbox account
${0}

To copy a specific ami from the sandbox account
${0} --ami ami-38296298
EOM
}

#default role to base
AMI_ROLE="base"
#default destination to production account
SRC_ACCT_ID="894947205914"
AMI_ID=""
SRC_REGION="us-west-2"

while [[ "$#" -gt 0 ]]; do case $1 in 
    -r|--role) AMI_ROLE="$2"; shift;;
    -a|--ami) AMI_ID="$2"; shift;;
    -s|--source_account) SRC_ACCT_ID="$2"; shift;;
    -h|--help) usage && exit 1;;
    *) echo "Unknown parameter passed $1"; exit 1;;
esac; shift; done

COLOR='\033[1;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Get current account
ACCOUNT_DETAILS=$(aws sts get-caller-identity)
ACCOUNT_ID=$(echo ${ACCOUNT_DETAILS} | jq -r '.Account')
echo -e "${COLOR}Destination account ID:${NC}" ${ACCOUNT_ID}

# Checking dependencies
if ! command -v jq >/dev/null 2>&1 ; then
    echo "jq is required but not installed. Aborting. See https://stedolan.github.io/jq/download/"
    exit 1
fi

echo -e "${COLOR}Source account ID:${NC}" ${SRC_ACCT_ID}

if [ $ACCOUNT_ID == $SRC_ACCT_ID ]; then
    echo -e "${RED}Destination and source account should be different. Make sure your AWS profile is not identity-dev (sandbox).${NC}"
    exit 1
fi
# Name=tag:Role,Values=$AMI_ROLE 
if [ -z $AMI_ID ]; then
    # Find latest image
    AMI_ID=$(aws ec2 describe-images --owners $SRC_ACCT_ID --filters Name=name,Values=*$AMI_ROLE* --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)
fi

echo -e $(aws ec2 describe-images --image-ids $AMI_ID --query 'Images[*].[ImageId,CreationDate,Name]' --output table)

# Describes the source AMI and stores its contents
AMI_DETAILS=$(aws ec2 describe-images --image-id ${AMI_ID}  --query 'Images[0]')

AMI_NAME=$(echo $AMI_DETAILS | jq -r '.Name')

NEW_AMI_ID=$(aws ec2 copy-image --source-image-id $AMI_ID --name "$AMI_NAME" --source-region $SRC_REGION --encrypted --output text)
echo -e "${COLOR}New Image Id: ${NC}" $NEW_AMI_ID

sleep 10
echo -e "Waiting for image to become available (this may take a couple of minutes)"
while :;do echo -n .;sleep 1;done &
trap "kill $!" EXIT  #Die with parent if we die prematurely
IMAGE_STATE=$(aws ec2 describe-images --image-ids $NEW_AMI_ID --query 'Images[*].[State]' --output text)
while [ $IMAGE_STATE == "pending" ] ; do
    sleep 15
    IMAGE_STATE=$(aws ec2 describe-images --image-ids $NEW_AMI_ID --query 'Images[*].[State]' --output text)
done

echo -e "Image Status: " $IMAGE_STATE

kill $! && trap " " EXIT

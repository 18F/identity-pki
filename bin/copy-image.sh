#!/bin/bash
set euo pipefail

run() {
    echo >&2 "+ $*"
    "$@"
}

usage() {
    cat >&2 << EOM
Usage: ${0} [-a ami_id] [-s sourceAccountId]
    -a,               ID of AMI to be copied.
    -s,               Source account ID for image.
    -r,               Image role to copy (base or rails).
    -h,               Show this message.

By default, this will copy the most recently shared base ami from the sandbox account.
For example:
To copy the latest shared rails image from the sandbox account
copy-image.sh -r rails

To copy the latest shared base image from the sandbox account
copy-image.sh
EOM
}

while getopts "a:s:r:" opt; do
    case $opt in
        h) usage && exit 1
        ;;
        a) AMI_ID="$OPTARG"
        ;;
        d) SRC_ACCT_ID="$OPTARG"
        ;;
        r) AMI_ROLE="$OPTARG"
        ;;
        \?) echo "Invalid option -$OPTARG" >&2
        ;;
    esac
done

COLOR='\033[1;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

SRC_REGION="us-west-2"

if [ "$SRC_ACCT_ID" == "" ]; then
    #default to sandbox account
    SRC_ACCT_ID="894947205914"
fi

if [ "$AMI_ROLE" == "" ]; then
    #default to base image
    AMI_ROLE="base"
fi

# Checking dependencies
if ! command -v jq >/dev/null 2>&1 ; then
    echo "jq is required but not installed. Aborting. See https://stedolan.github.io/jq/download/"
fi

echo -e "${COLOR}Source account ID:${NC}" ${DST_ACCT_ID}

if [ "$AMI_ID" == "" ]; then
    # Find latest image
    AMI_ID=$(aws ec2 describe-images --filters Name=owner-id,Values=$SRC_ACCT_ID --query 'Images[*].[ImageId]' --output text | sort -k2 -r | head -n1)
fi

echo -e $(aws ec2 describe-images --image-ids $AMI_ID --query 'Images[*].[ImageId,CreationDate,Name]' --output text)

# Describes the source AMI and stores its contents
AMI_DETAILS=$(aws ec2 describe-images --image-id ${AMI_ID}  --query 'Images[0]')

AMI_NAME=$(echo $AMI_DETAILS | jq -r '.Name')
AMI_DESCRIPTION=$(echo $AMI_DETAILS | jq -r '.Description')

NEW_AMI_ID=$(aws ec2 copy-image --source-image-id $AMI_ID --name  --source-region $SRC_REGION --encrypted --name $AMI_NAME --output text)
echo -e ("New Image Id: " $NEW_AMI_ID)

sleep 5
echo -e ("Copying ")
while :;do echo -n .;sleep 1;done &
trap "kill $!" EXIT  #Die with parent if we die prematurely
IMAGE_STATE=$(aws ec2 describe-images --image-ids ami-0f50ce402f6f41e12 --query 'Images[*].[State]' --output text)
while [ $IMAGE_STATE == "pending" ] ; do
    sleep 10
done
kill $! && trap " " EX
echo -e ("Image Status:" $IMAGE_STATE)

# Copy Tags
AMI_TAGS=$(echo ${AMI_DETAILS} | jq '.Tags')"}"
if [ "${AMI_TAGS}" != "null}" ]; then
    NEW_AMI_TAGS="{\"Tags\":"$(echo ${AMI_TAGS} | tr -d ' ')
    $(aws ec2 create-tags --resources ${NEW_AMI_ID} --cli-input-json ${NEW_AMI_TAGS} 
    echo -e "${COLOR}Tags added sucessfully${NC}"
fi

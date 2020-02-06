#!/bin/bash
set euo pipefail

run() {
    echo >&2 "+ $*"
    "$@"
}

usage() {
    cat >&2 << EOM
Usage: ${0} [-a ami_id] [-d share to account id]
-a,               ID of AMI to be copied.
-d,               Account Id to share ami with.
-r                Image role to share (base or rails).
-h,               Show this message.

By default, will use the latest base image ami and share with the production account.

For example:
To share the latest rails image with the production account
share-image.sh -r rails

To share the latest base image with the production account
share-image.sh

EOM
}

while getopts "a:d:r:" opt; do
    case $opt in
        h) usage && exit 1
        ;;
        a) AMI_ID="$OPTARG"
        ;;
        d) DST_ACCT_ID="$OPTARG"
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

if [ "$DST_ACCT_ID" == "" ]; then
    #default to production account
    DST_ACCT_ID="555546682965"
fi

if [ "$AMI_ROLE" == "" ]; then
    #default to base image
    AMI_ROLE="base"
fi

# Checking dependencies
if ! command -v jq >/dev/null 2>&1 ; then
    echo "jq is required but not installed. Aborting. See https://stedolan.github.io/jq/download/"
fi

echo -e "${COLOR}Destination account ID:${NC}" ${DST_ACCT_ID}

# Get current account
ACCOUNT_DETAILS=$(aws sts get-caller-identity)
ACCOUNT_ID=$(echo ${ACCOUNT_DETAILS} | jq -r '.Account')
echo -e "${COLOR}Source account ID:${NC}" ${ACCOUNT_ID}

if [ "$AMI_ID" == "" ]; then
    # Find latest image
    AMI_ID=$(aws ec2 describe-images --filters Name=owner-id,Values=$ACCOUNT_ID,Name=tag:Role,Values=$AMI_ROLE --query 'Images[*].[ImageId]' --output text | sort -k2 -r | head -n1)
fi

echo -e $(aws ec2 describe-images --image-ids $AMI_ID --query 'Images[*].[ImageId,CreationDate,Name]' --output text)

# Describes the source AMI and stores its contents
AMI_DETAILS=$(aws ec2 describe-images --image-id ${AMI_ID} --query 'Images[0]')

# Retrieve the snapshots and key ID's
SNAPSHOT_IDS=$(echo ${AMI_DETAILS} | jq -r '.BlockDeviceMappings[] | select(has("Ebs")) | .Ebs.SnapshotId' 
echo -e "${COLOR}Snapshots found:${NC}" ${SNAPSHOT_IDS}

# Give permissions to share ami with account
run aws ec2 modify-image-attribute --image-id $AMI_ID --launch-permission "Add=[{UserId=$DST_ACCT_ID}]" 
echo -e "${COLOR}Permission granted to ami:${NC}" ${AMI_ID}

# Iterate over the snapshots, adding permissions for the destination account
echo $SNAPSHOT_IDS | while read snapshotid; do
    run aws ec2 modify-snapshot-attribute --snapshot-id $snapshotid --attribute createVolumePermission --operation-type add --user-ids $DST_ACCT_ID 
    echo -e "${COLOR}Permission added to Snapshot(s):${NC} ${snapshotid}"
done

#!/bin/bash
set -euo pipefail

run() {
    echo >&2 "+ $*"
    "$@"
}

usage() {
    cat >&2 << EOM
Usage: ${0} [-a ami_id] [-d share to account id] [-r role]
Usage: ${0} [--ami ami_id] [-destination_account share to account id] [--role role]
-a|--ami,               ID of AMI to be copied.
-d|destination_account, Account Id to share ami with.
-r|--role               Image role to share (base or rails).
-h|--help,              Show this message.

By default, will use the latest base image ami and share with the production account.

For example:
To share the latest rails image with the production account
${0} --role rails

To share the latest base image with the production account
${0}

To share a specific ami with the production account
${0} --ami ami-12345676

EOM
}

#default role to base
AMI_ROLE="base"
#default destination to production account
DST_ACCT_ID="555546682965"
AMI_ID=""

while [[ "$#" -gt 0 ]]; do case $1 in 
    -r|--role) AMI_ROLE="$2"; shift;;
    -a|--ami) AMI_ID="$2"; shift;;
    -d|--destination_account) DST_ACCT_ID="$2"; shift;;
    -h|--help) usage && exit 1;;
    *) echo "Unknown parameter passed $1"; exit 1;;
esac; shift; done

COLOR='\033[1;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Checking dependencies
if ! command -v jq >/dev/null 2>&1 ; then
    echo "jq is required but not installed. Aborting. See https://stedolan.github.io/jq/download/"
    exit 1
fi

echo -e "${COLOR}Destination account ID:${NC}" ${DST_ACCT_ID}

# Get current account
ACCOUNT_DETAILS=$(aws sts get-caller-identity)
ACCOUNT_ID=$(echo ${ACCOUNT_DETAILS} | jq -r '.Account')
echo -e "${COLOR}Source account ID:${NC}" ${ACCOUNT_ID}
if [ $ACCOUNT_ID != "894947205914" ]; then
    echo -e "${RED}Current account should be identity-dev (sandbox).${NC}"
    exit 1
fi

if [ -z $AMI_ID ]; then
    # Find latest image
    AMI_ID=$(aws ec2 describe-images --owners $ACCOUNT_ID --filters Name=tag:Role,Values=$AMI_ROLE --query 'sort_by(Images, &CreationDate)[-1].ImageId' --output text)
fi

echo -e $(aws ec2 describe-images --image-ids $AMI_ID --query 'Images[*].[ImageId,CreationDate,Name]' --output table)

# Describes the source AMI and stores its contents
AMI_DETAILS=$(aws ec2 describe-images --image-id ${AMI_ID} --query 'Images[0]')

# Retrieve the snapshots and key ID's
SNAPSHOT_IDS=$(echo ${AMI_DETAILS} | jq -r '.BlockDeviceMappings[] | select(has("Ebs")) | .Ebs.SnapshotId')
echo -e "${COLOR}Snapshots found:${NC}" ${SNAPSHOT_IDS}

# Give permissions to share ami with account
run aws ec2 modify-image-attribute --image-id $AMI_ID --launch-permission "Add=[{UserId=$DST_ACCT_ID}]" 
echo -e "${COLOR}Permission granted to ami:${NC}" ${AMI_ID}

# Iterate over the snapshots, adding permissions for the destination account
#echo $SNAPSHOT_IDS | while read snapshotid; do
for snapshotid in $SNAPSHOT_IDS; do
    run aws ec2 modify-snapshot-attribute --snapshot-id $snapshotid --attribute createVolumePermission --operation-type add --user-ids $DST_ACCT_ID
    echo -e "${COLOR}Permission added to Snapshot(s):${NC} ${snapshotid}"
done

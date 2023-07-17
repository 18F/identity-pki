#!/bin/sh
#
# This script dumps a bunch of scan results of the images that we build/use that
# can be uploaded to the FedRAMP scan artifacts folder.  They appear in the
# current directory and are named IMAGENAME-scan.txt.
#

IMAGES=$(aws s3 cp s3://login-gov.secrets.217680906704-us-west-2/common/gitlab_env_runner_allowed_images - | grep -v '^#' | grep -v '.grep_v(/XXXXXdate_separatorXXXXX/)')

for i in $IMAGES ; do
	IMAGE=$(echo "$i" | sed 's/.*amazonaws.com\///')
	REPO=$(echo "$IMAGE" | awk -F@ '{print $1}')
	SHA=$(echo "$IMAGE" | awk -F@ '{print $2}')
	IMAGENAME=$(echo "$REPO" | awk -F/ '{print $2}')
	rm -rf "$IMAGENAME-scan.txt"
	aws ecr describe-image-scan-findings \
		--repository-name "$REPO" \
		--image-id imageDigest="$SHA" \
		--output table > "$IMAGENAME-scan.txt"
done


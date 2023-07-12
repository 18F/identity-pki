#!/bin/sh

IMAGES=$(aws s3 cp s3://login-gov.secrets.217680906704-us-west-2/common/gitlab_env_runner_allowed_images - | grep -v 000000000000.dkr.ecr)

for i in $IMAGES ; do
	IMAGE=$(echo "$i" | sed 's/.*amazonaws.com\///')
	REPO=$(echo "$IMAGE" | awk -F@ '{print $1}')
	SHA=$(echo "$IMAGE" | awk -F@ '{print $2}')
	IMAGENAME=$(echo "$REPO" | awk -F/ '{print $2}')
	rm -rf "/tmp/$IMAGENAME-scan.txt"
	aws ecr describe-image-scan-findings \
		--repository-name "$REPO" \
		--image-id imageDigest="$SHA" \
		--output table > "/tmp/$IMAGENAME-scan.txt"
done


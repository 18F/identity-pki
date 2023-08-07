#!/bin/sh
#
# This script dumps a bunch of scan results of the images that we build/use that
# can be uploaded to the FedRAMP scan artifacts folder.  They appear in the
# current directory and are named IMAGENAME-scan.txt.
#


REPOS=$(aws ecr describe-repositories | jq -r '.repositories[] | select(.repositoryName | test("blessed$")) | .repositoryName')

for IMAGE in $REPOS ; do
	REPO=$(echo "$IMAGE" | awk -F@ '{print $1}')
	IMAGENAME=$(echo "$REPO" | awk -F/ '{print $2}')
	rm -rf "$IMAGENAME-scan.txt"
	aws ecr describe-image-scan-findings \
		--repository-name "$REPO" \
		--image-id imageTag="latest" \
		--output table > "$IMAGENAME-scan.txt"
done


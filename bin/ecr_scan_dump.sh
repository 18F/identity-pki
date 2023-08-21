#!/bin/sh
#
# This script dumps a bunch of scan results of the images that we build/use that
# can be uploaded to the FedRAMP scan artifacts folder.  They appear in the
# current directory and are named IMAGENAME-scan.txt.
#

REPOS=$(aws ecr describe-repositories | jq -r '.repositories[] | select(.repositoryName | test("blessed$")) | .repositoryName')

for REPO in $REPOS ; do
	IMAGENAME=$(echo "$REPO" | awk -F/ '{print $2}')
	rm -rf "$IMAGENAME-scan.txt"
	aws ecr describe-image-scan-findings \
		--repository-name "$REPO" \
		--image-id imageTag="latest" \
		--output json | jq .imageScanFindings.enhancedFindings | jq -r '(. | map(leaf_paths) | unique) as $cols | map (. as $row | ($cols | map(. as $col | $row | getpath($col)))) as $rows | ([($cols | map(. | map(tostring) | join(".")))] + $rows) | map(@csv) | .[]' > "$IMAGENAME-scan.csv"
done


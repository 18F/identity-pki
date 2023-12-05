#!/bin/sh
#
# This script blesses our latest crop of images.  We should probably do
# this every week or two.
#
# You will need to edit all the XXX'es to be the proper sha256es from the latest
# passing builds, then run this with aws-vault against tooling-prod.
# After that, go edit .gitlab-ci.yml and add those SHAs to that, create a PR,
# and then watch the pipelines to make sure that dev and gitstaging deploys and
# tests are happy!
#

IMAGES="
	217680906704.dkr.ecr.us-west-2.amazonaws.com/cd/env_deploy@sha256:XXX
	217680906704.dkr.ecr.us-west-2.amazonaws.com/cd/env_stop@sha256:XXX
	217680906704.dkr.ecr.us-west-2.amazonaws.com/cd/env_test@sha256:XXX
	217680906704.dkr.ecr.us-west-2.amazonaws.com/cd/gitlab_deploy@sha256:XXX
	217680906704.dkr.ecr.us-west-2.amazonaws.com/cd/gitlab_test@sha256:XXX
"

for i in $IMAGES ; do
	BLESSED=$(echo "$i" | sed 's/@sha256.*/\/blessed/')
	crane copy "$i" "$BLESSED"

	BLESSEDIMG=$(echo "$i" | sed 's/@sha256/\/blessed@sha256/')
	bin/sign_image.sh image_signing "$BLESSEDIMG"
done


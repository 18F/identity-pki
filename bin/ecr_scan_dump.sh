#!/bin/sh

IMAGES="
	cd/env_deploy@sha256:de71d76fb4e2dcbf3f0e3dfd55169977fb95e8510ccec67f3fa4e87429b9800d
	cd/env_stop@sha256:fa800ff29cd9b8ba1b1afa0f81227e89459d86cdacc084296e7d3c77363e2af9
	cd/env_test@sha256:46a48af66a345bf50aacca5dc5e649d9482564bfad294451ea40666839712ac8
	cd/gitlab_deploy@sha256:9235830d3b0c3abfe316c717a7c36865adf7d8cfe898579d301fa99cadbe76bd
	cd/gitlab_test@sha256:36aa91003cc13f5a0ecdb17fd04ac38443f5d20d6fb6d10c8ab138668700b5d3
	cd/terraform_apply@sha256:1f10c7311fcaff979028bac7ad9d052df3aa3feba9770c85438ebe220c5676b8
	cd/terraform_plan@sha256:52ab356460a2ec9ecdb4aa3a1d0bf0303c34ec726c93fd34274505acb3182317
"


for i in $IMAGES ; do
	REPO=$(echo "$i" | awk -F@ '{print $1}')
	SHA=$(echo "$i" | awk -F@ '{print $2}')
	IMAGENAME=$(echo "$REPO" | awk -F/ '{print $2}')
	aws ecr describe-image-scan-findings \
		--repository-name "$REPO" \
		--image-id imageDigest="$SHA" \
		--output table > /tmp/"$IMAGENAME"-scan.txt
done


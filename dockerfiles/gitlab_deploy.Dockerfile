FROM alpine:3

COPY dockerfiles/gitlab_deploy.sh /usr/local/bin/gitlab_deploy.sh

RUN apk add aws-cli git curl bash jq coreutils tzdata

# install terraform
ENV TF_VERSION=1.3.5
ENV TF_SHA256=ac28037216c3bc41de2c22724e863d883320a770056969b8d211ca8af3d477cf

RUN curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" > tf.zip && \
	echo "${TF_SHA256}  tf.zip" | sha256sum -c - && \
	unzip tf.zip && \
	rm tf.zip && \
	mv terraform /usr/local/bin/

# prepare to install provider plugins here
RUN mkdir /terraform-bundle
COPY versions.tf /terraform-bundle
COPY versions.tf.old* /terraform-bundle

# install provider plugins
RUN cd /terraform-bundle && \
	for i in versions.tf versions.tf.old* ; do \
		mv "$i" versions.tf ; \
		terraform init ; \
		terraform providers mirror -platform=linux_amd64 ./plugins ; \
		rm -rf .terraform .terraform.lock.hcl ; \
	done


# set up deployuser
RUN adduser -D deployuser
RUN chown -R deployuser /terraform-bundle

# get rid of suid/sgid stuff 
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

USER deployuser
ENTRYPOINT ["/usr/local/bin/gitlab_deploy.sh"]

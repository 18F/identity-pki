FROM alpine:3

COPY dockerfiles/env_deploy.sh /usr/local/bin/env_deploy.sh

RUN apk add aws-cli git curl bash jq coreutils tzdata

# install terraform
ENV TF_VERSION=1.1.3
ENV TF_SHA256=b215de2a18947fff41803716b1829a3c462c4f009b687c2cbdb52ceb51157c2f

RUN curl -s "https://releases.hashicorp.com/terraform/${TF_VERSION}/terraform_${TF_VERSION}_linux_amd64.zip" > tf.zip && \
	echo "${TF_SHA256}  tf.zip" | sha256sum -c - && \
	unzip tf.zip && \
	rm tf.zip && \
	mv terraform /usr/local/bin/

# prepare to install provider plugins here
RUN mkdir /terraform-bundle
COPY versions.tf versions.tf.old* /terraform-bundle

# install current provider plugins
RUN cd /terraform-bundle && \
	terraform init && \
	terraform providers mirror -platform=linux_amd64 ./plugins && \
	rm -rf .terraform .terraform.lock.hcl

# install old provider plugins
RUN cd /terraform-bundle && \
	for i in versions.tf.old* ; do \
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
ENTRYPOINT ["/usr/local/bin/env_deploy.sh"]

FROM public.ecr.aws/docker/library/ruby:3.2.2-alpine

COPY dockerfiles/env_deploy.sh /usr/local/bin/env_deploy.sh

RUN apk add aws-cli git curl bash jq coreutils tzdata

# install terraform
ENV TF_VERSION=1.5.5
ENV TF_SHA256=ad0c696c870c8525357b5127680cd79c0bdf58179af9acd091d43b1d6482da4a

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
ENTRYPOINT ["/usr/local/bin/env_deploy.sh"]

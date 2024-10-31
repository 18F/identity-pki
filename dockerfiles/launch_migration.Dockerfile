FROM public.ecr.aws/docker/library/alpine:3

COPY dockerfiles/launch_migration.sh /usr/local/bin/launch_migration.sh

RUN apk add aws-cli git curl bash jq coreutils tzdata build-base

# set up deployuser
RUN adduser -D deployuser

RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

USER deployuser
ENTRYPOINT ["/usr/local/bin/launch_migration.sh"]

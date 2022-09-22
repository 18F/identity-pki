FROM alpine:3

COPY dockerfiles/env_stop.sh /usr/local/bin/env_stop.sh

RUN apk add aws-cli jq bash

# Set up stopuser
RUN adduser -D stopuser

# get rid of suid/sgid stuff
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

USER stopuser
ENTRYPOINT ["/usr/local/bin/env_stop.sh"]

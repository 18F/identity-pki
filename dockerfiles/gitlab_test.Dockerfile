FROM alpine:3

COPY dockerfiles/gitlab_test.sh /usr/local/bin/gitlab_test.sh

RUN apk add go aws-cli
RUN GOBIN=/usr/local/bin go install github.com/gruntwork-io/terratest/cmd/terratest_log_parser@latest

# set up testuser
RUN adduser -D testuser

# get rid of suid/sgid stuff
RUN find / -perm /6000 -type f -exec chmod a-s {} \; || true

USER testuser
ENTRYPOINT ["/usr/local/bin/gitlab_test.sh"]

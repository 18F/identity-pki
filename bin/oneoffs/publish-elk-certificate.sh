#!/bin/bash

set -euo pipefail

# shellcheck source=/dev/null
. "$(dirname "$0")/../lib/common.sh"

usage() {
    cat >&2 <<EOM
Usage: $(basename "$0") ENVIRONMENT_NAME

Used only for environments with a single ELK node provisioned by the terraform
chef provisioner.  Logs into that ELK instance and uploads the self signed
certificate to the proper s3 location where it can be discovered by the
service_discovery library.
EOM
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

ENVIRONMENT=$1
INSTANCE_ID=$(bin/ls-servers -qqbH -e "$ENVIRONMENT" -n "*-elk-*" | cut -f1)
REMOTE_CERT_NAME="elk-$INSTANCE_ID.$ENVIRONMENT.login.gov-legacy-elk.crt"

# 1. Download the certificate from ELK
TEMP_DIR="$(mktemp -d)"
run "$(dirname "$0")/../scp-instance" "$INSTANCE_ID:/etc/logstash/elk.login.gov.cacrt" "$TEMP_DIR"

# 2. Upload to both s3 certificate buckets
run aws s3 cp "$TEMP_DIR/elk.login.gov.cacrt" "s3://login-gov-internal-certs-test-us-west-2-555546682965/$ENVIRONMENT/$REMOTE_CERT_NAME"
run aws s3 cp "$TEMP_DIR/elk.login.gov.cacrt" "s3://login-gov.internal-certs.555546682965-us-west-2/$ENVIRONMENT/$REMOTE_CERT_NAME"

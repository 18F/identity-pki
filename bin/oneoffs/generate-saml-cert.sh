#!/bin/bash
set -euo pipefail

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") COMMON_NAME

Generate saml certificate and key in the current directory for COMMON_NAME.

For example:

    $(basename "$0") staging.login.gov

EOM
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

cn="$1"
year=$(date +%Y)

set -x
openssl req -newkey rsa:2048 -sha256 -x509 -days 395 \
    -subj "/C=US/ST=District of Columbia/L=Washington/O=GSA/OU=Login.gov/CN=$cn" \
    -keyout "saml$year.key.enc" -out "saml$year.crt"

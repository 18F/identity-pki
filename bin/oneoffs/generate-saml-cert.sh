#!/bin/bash
set -euo pipefail

usage() {
    cat >&2 <<EOM
usage: $(basename "$0") ENVIRONMENT

Generate saml certificate and key in SAML/YEAR for ENVIRONMENT.
Will automatically determine COMMON_NAME based on ENVIRONMENT
provided and will generate cert to expire on April 1 of the
following year.

For example:

    $(basename "$0") staging

EOM
}

if [ $# -lt 1 ]; then
    usage
    exit 1
fi

ENV_NAME="$1"
case ${ENV_NAME} in
  staging)   COMMON_NAME='staging.login.gov'               ;;
  prod)      COMMON_NAME='login.gov'                       ;;
  localhost) COMMON_NAME='localhost'                       ;;
  *)         COMMON_NAME="${ENV_NAME}.identitysandbox.gov" ;;
esac

DATE_TODAY=$(date -j +%s)
DATE_EXPIRE=$(date -v2d -v4m -v+1y +%s)
DAYS=$(echo $(( (DATE_EXPIRE-DATE_TODAY)/86400 )))
YEAR=$(date +%Y)

mkdir -p "SAML/${ENV_NAME}"
set -x
openssl req -newkey rsa:2048 -sha256 -x509 -days "${DAYS}" \
    -subj "/C=US/ST=District of Columbia/L=Washington/O=GSA/OU=Login.gov/CN=${COMMON_NAME}" \
    -keyout "SAML/${ENV_NAME}/saml${YEAR}.key.enc" -out "SAML/${ENV_NAME}/saml${YEAR}.crt"

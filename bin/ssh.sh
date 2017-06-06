#!/bin/bash
set -euo pipefail

ENVIRON=${1:-''}
HOST=${2:-'idp1-0'}

if [ -z "$ENVIRON" ]; then
  cat <<EOS
Usage: $0 [environment] (host, default = idp1-0)
SSHes into a box, proxing through the jumphost. It defaults to idp1-0.
EOS
  exit 1
fi

"$(dirname "$0")"/clear-keygen.sh

PROXY_COMMAND="ssh jumphost.${ENVIRON}.login.gov -W %h:%p"

ssh -t -o ProxyCommand="${PROXY_COMMAND}" "ubuntu@$HOST"

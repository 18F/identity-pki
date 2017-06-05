#!/bin/bash

ENVIRON=${1:-''}

if [ -z "$ENVIRON" ]; then
  cat <<EOS
Usage: $0 [environment]
Creates an SSH tunnel through the jumphost to the ELK host
and opens ELK in your browser.
EOS
  exit 1
fi

"$(dirname "$0")"/clear-keygen.sh

open https://localhost:8443/app/kibana

PROXY_COMMAND="ssh jumphost.${ENVIRON}.login.gov -W %h:%p"

ssh -A -t -o ProxyCommand="${PROXY_COMMAND}" ubuntu@elk -L 8443:localhost:8443 -N

#!/bin/bash

ENVIRON=${1:-''}

if [ -z "$ENVIRON" ]; then
  cat <<EOS
Usage: $0 [environment]
Creates an SSH tunnel through the jumphost to the Jenkins host
and opens Jenkins in your browser.
EOS
  exit 1
fi

"$(dirname "$0")"/clear-keygen.sh

open https://localhost:8443/

PROXY_COMMAND="ssh jumphost.${ENVIRON}.login.gov -W %h:%p"

ssh -A -t -o ProxyCommand="${PROXY_COMMAND}" ubuntu@jenkins -L 8443:localhost:8443 -N

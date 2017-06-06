#!/bin/bash
ENVIRON=${1:-''}

if [ -z "$ENVIRON" ]; then
  cat <<EOS
Usage: $0 [environment]
Opens a rails console
EOS
  exit 1
fi

"$(dirname "$0")"/clear-keygen.sh

PROXY_COMMAND="ssh jumphost.${ENVIRON}.login.gov -W %h:%p"

ssh -t -o ProxyCommand="${PROXY_COMMAND}" ubuntu@idp1-0.login.gov.internal -- 'cd /srv/idp/current; bundle exec rails c'

#!/bin/bash
ENVIRON=${1:-''}

#!/bin/bash

run() {
  echo >&2 "+ $*"
  "$@"
}

if [ -z "$ENVIRON" ]; then
  cat <<EOS
Usage: $0 [environment]
Opens a rails console
EOS
  exit 1
fi

PROXY_COMMAND="ssh jumphost.${ENVIRON}.login.gov -W %h:%p"

script="$(dirname "$0")/ssh.sh"

run "$script" idp1-0 "$ENVIRON" -t -- \
  "sudo -i -uubuntu sh -c 'cd /srv/idp/current; bundle exec rails c'"

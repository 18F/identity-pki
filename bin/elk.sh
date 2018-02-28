#!/bin/bash

ENVIRON=${1:-''}

run() {
  echo >&2 "+ $*"
  "$@"
}

if [ -z "$ENVIRON" ]; then
  cat <<EOS
Usage: $0 [environment]
Creates an SSH tunnel through the jumphost to the Jenkins host
and opens Jenkins in your browser.
EOS
  exit 1
fi

script="$(dirname "$0")/ssh.sh"

run "$script" elk "$ENVIRON" -t -L 8443:localhost:8443 -N

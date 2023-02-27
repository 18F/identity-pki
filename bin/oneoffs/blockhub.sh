#!/bin/bash

# Adds github.com / api.github.com to your /etc/hosts file.
# Use to test scenarios where GitHub is unreachable from a local machine.

set -euo pipefail

. "$(dirname "$0")/../lib/common.sh"

if [[ $(id -u) != 0 ]] ; then
  echo_red "Must run as root (sudo)!"
  exit 1
fi

for GITHUB_URL in 'github.com' 'api.github.com' ; do
  HOSTS_LINE="127.0.0.1 ${GITHUB_URL}    # added by $(basename ${0})"
  if [[ ! $(grep "${GITHUB_URL}" '/etc/hosts' ) ]] ; then
    if prompt_yn "Block '${GITHUB_URL}' in /etc/hosts ?" ; then
      echo "${HOSTS_LINE}" >> /etc/hosts
    fi
  else
    if [[ $(grep "${HOSTS_LINE}" '/etc/hosts') ]] ; then
      if prompt_yn "Unblock '${GITHUB_URL}' from /etc/hosts ?" ; then
        sed -i '' "/$HOSTS_LINE/d" /etc/hosts
      fi
    else
      echo_red "${GITHUB_URL} found in /etc/hosts, but wasn't added by this script."
      echo_red "Verify and remove manually!"
      exit 1
    fi
  fi
done
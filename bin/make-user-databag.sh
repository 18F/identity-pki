#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 1 ] ; then
    echo "Usage: $0 <username>"
    echo "  Creates a databag for <username>"
    exit 1
fi

function run() {
  echo "+ $*" >&2
  "$@"
}

USERNAME=$1

# cd to repo root
cd "$(dirname "$0")/.."

echo "Creating chef user data bag for $USERNAME"
mkdir -p kitchen/data_bags/users/
if [ -e "kitchen/data_bags/users/$USERNAME.json" ]; then
    echo "File: kitchen/data_bags/users/$USERNAME.json already exists!  Not creating."
    exit 1
fi

DEFAULT_FULL_NAME="$(id -F)"
read -r -p "Full name [$DEFAULT_FULL_NAME]: " FULL_NAME
if [ -z "$FULL_NAME" ]; then
  FULL_NAME="$DEFAULT_FULL_NAME"
fi

# Note that the bcrypt password hash is supported by Apache but not by
# glibc crypt(). We use the hash for HTTP Basic Auth, not for unix user
# authentication (even though it does end up in /etc/shadow because Computer).
PASSWORD_HASH="$(htpasswd -n -B -C12 "$USERNAME")"
PASSWORD_HASH="$(cut -d: -f 2- <<< "$PASSWORD_HASH")"

read -r -p "Unique UID (hit Enter to use next available): " USER_UID
if [ -z "$USER_UID" ]; then
  USER_UID="$(run bin/next-uid.sh)"
fi

read -r -p "SSH public key (hit Enter to attempt your PIV card): " PUBLIC_KEY
if [ -z "$PUBLIC_KEY" ]; then
  PUBLIC_KEY="$(run pkcs15-tool --read-ssh-key 1) for $USER"
fi

tee "kitchen/data_bags/users/$USERNAME.json" <<EOF
{
 "id": "$USERNAME",
 "password": "$PASSWORD_HASH",
 "ssh_keys": [
   "$PUBLIC_KEY"
 ],
 "groups": [
   "$USERNAME",
   "adm",
   "ci",
   "dev",
   "qa",
   "sudo"
 ],
 "uid": $USER_UID,
 "shell": "/bin/bash",
 "comment": "$FULL_NAME"
}
EOF

echo
echo "Successfully created: kitchen/data_bags/users/$USERNAME.json"

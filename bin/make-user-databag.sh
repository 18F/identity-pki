#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 1 ] ; then
    echo "Usage: $0 <username>"
    echo "  Creates a databag for <username>"
    exit 1
fi

USERNAME=$1

# cd to repo root
cd "$(dirname "$0")/.."

echo "Creating chef user data bag for $USERNAME"
mkdir -p kitchen/data_bags/users/
if [ -e "kitchen/data_bags/users/$USERNAME.json" ]; then
    echo "File: kitchen/data_bags/users/$USERNAME.json already exists!  Not creating."
    exit 1
fi

read -r -p "Full name: " FULL_NAME
# Note that the bcrypt password hash is supported by Apache but not by
# glibc crypt(). We use the hash for HTTP Basic Auth, not for unix user
# authentication (even though it does end up in /etc/shadow because Computer).
PASSWORD_HASH="$(htpasswd -n -B -C12 "$USERNAME")"
PASSWORD_HASH="$(cut -d: -f 2- <<< "$PASSWORD_HASH")"
read -r -p "SSH public key: " PUBLIC_KEY
read -r -p "Unique UID: " USER_UID
cat > "kitchen/data_bags/users/$USERNAME.json" <<EOF
{
 "id": "$USERNAME",
 "password": "$PASSWORD_HASH",
 "ssh_keys": [
   "$PUBLIC_KEY"
 ],
 "groups": [
   "$USERNAME",
   "adm",
   "dev",
   "qa",
   "tf",
   "dm",
   "pt",
   "demo",
   "sudo"
 ],
 "uid": $USER_UID,
 "shell": "/bin/bash",
 "comment": "$FULL_NAME"
}
EOF
echo "Successfully created: kitchen/data_bags/users/$USERNAME.json"

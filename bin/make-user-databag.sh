#!/bin/bash

# http://redsymbol.net/articles/unofficial-bash-strict-mode/
set -euo pipefail

if [ $# -ne 1 ] ; then
    echo "Usage: $0 <username>"
    echo "  Creates a databag for <username>"
    exit 1
fi

USERNAME=$1

echo "Creating chef user data bag for $USERNAME"
mkdir -p kitchen/data_bags/users/
if [ -e kitchen/data_bags/users/$USERNAME.json ]; then
    echo "File: kitchen/data_bags/users/$USERNAME.json already exists!  Not creating."
    exit 1
fi

read -p "Full name: " FULL_NAME
read -p "Username: " USERNAME
PASSWORD_HASH=$(htpasswd -n $USERNAME)
read -p "SSH public key: " PUBLIC_KEY
read -p "Unique UID: " USER_UID
cat > kitchen/data_bags/users/$USERNAME.json <<EOF
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

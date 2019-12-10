#!/bin/sh

cat >&2 <<EOM
This script is useful for checking whether the Atomicorp OSSEC apt repos are
working.
https://github.com/18F/identity-devops/issues/1820
EOM

dig +short updates.atomicorp.com | sort | while read -r ip; do
    echo "$ip:"
    curl -sSI -H 'Host: updates.atomicorp.com' \
        "http://$ip/channels/atomic/ubuntu/dists/bionic/Release" | sed 's/^/    /'
done

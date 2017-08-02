#!/bin/sh
#
# This is a quick script that you should probably never use.
# It is more proper to relaunch the node.  However, sometimes this
# is faster to do, so here it is.
#

usage() {
	echo "usage: $0 <env> <host>"
	echo "example: $0 pt jumphost"
	exit 1
}

if [ -z "$1" -o -z "$2" ] ; then
	usage
fi

ssh -q ubuntu@$2 "sudo mv /etc/chef/trusted_certs /etc/chef/trusted_certs.old"
ssh -q ubuntu@$2 "sudo mv /etc/chef/client.pem /etc/chef/client.pem.old"
knife bootstrap $2 -x ubuntu -N $2.$1 -E $1 --sudo --node-ssl-verify-mode none

echo "be sure to set the runlist for $2"


#!/bin/sh
#
# This script copies the user databag items from an local directory
# to an env.  
#

env=$1
jsondir=$2

usage() {
	echo "usage:  $0 <env> <jsondir>"
	echo "  where env is a knife block environment, and jsondir is where you want to get the user json"
	echo "example:  $0 old /Users/timothyspencer/usersjson"
}

if [ -z "$env" ] ; then
	usage
	exit 2
fi
if [ ! -d "$jsondir" ] ; then
	usage
	exit 3
fi

# move the users
knife block use $env

for i in $jsondir/* ; do
	echo copying $i to $env
	knife data bag from file users $i
done

knife block list


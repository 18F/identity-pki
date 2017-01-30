#!/bin/sh
#
# This script copies the user databag items from an env
# to local directory.  
#

oldenv=$1
jsondir=$2

usage() {
	echo "usage:  $0 <oldenv> <jsondir>"
	echo "  where oldenv is a knife block environment, and jsondir is where you want to put the user json"
	echo "example:  $0 old /Users/timothyspencer/usersjson"
}

if [ -z "$oldenv" ] ; then
	usage
	exit 2
fi
if [ ! -d "$jsondir" ] ; then
	usage
	exit 3
fi

# move the users
knife block use $oldenv

for i in `knife data bag show users` ; do
	echo copying $i to $jsondir
	knife data bag show users $i -Fj > $jsondir/$i.json
done

knife block list


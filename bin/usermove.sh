#!/bin/sh
#
# This script copies the encrypted user databag items from an old env
# to a new one.  It's used when you create a new chef-server.
#

oldenv=$1
newenv=$2

usage() {
	echo "usage:  $0 <oldenv> <newenv>"
	echo "  where oldenv and newenv are knife block environments"
	echo "example:  $0 old tf"
}

if [ -z "$newenv" ] ; then
	usage
	exit 1
fi
if [ -z "$oldenv" ] ; then
	usage
	exit 2
fi

# test to make sure these are valid knife block environments
for i in $oldenv $newenv ; do
	knife block list | grep \* | awk '{print $2}' | egrep "^$i$" >/dev/null
	if [ $? != 0 ]; then
		usage
		exit 3
	fi
	echo $i is a valid knife block environment
done

# make sure databag is set up (need no encryption)
knife block use $newenv
if knife data bag show users >/dev/null 2>&1 ; then
	echo target databag already set up
else
	knife data bag create users
fi

# move the users
knife block use $oldenv

for i in `knife data bag show users` ; do
	echo moving $i
	knife data bag show users $i -Fj > /tmp/$$.json
	knife block use $newenv
	knife data bag from file users /tmp/$$.json
	knife block use $oldenv
done

knife block use $newenv
knife block list

rm -f /tmp/$$.json


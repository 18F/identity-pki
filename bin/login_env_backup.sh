#!/bin/sh
#
# This script backs up the infrastructure stuff into a tarball that
# we can use to reconstitute an env later on
#

usage() {
	echo "usage:   $0 <env> [-h]"
	echo "example: $0 tf"
	echo "  this will create an envbackup-tf-<datestring>.tar.gz file in /tmp"
	echo "example: $0 <env> -h"
	echo "  this will create an envbackup-tf-<datestring>.tar.gz file and a tar of the users homedir"
}

if [ -z "$1" ] ; then
	echo "no environment specified"
	usage
	exit 1
fi


DIRNAME="envbackup-$1-`date +%Y-%m-%d-%H%M`"
DIR="/tmp/$DIRNAME"
rm -rf $DIR
mkdir $DIR
cd $DIR

# databag
knife data bag show -Fj config app > config_app_databag.json

# users
mkdir users
for i in `knife data bag show users` ; do
	knife data bag show -Fj users $i > users/$i.json
done

# certs
ssh -q ubuntu@idp1-0 sudo tar cf - /etc/letsencrypt | gzip -9 > idp_letsencryptdir.tar.gz

# environments
mkdir environments
for i in `knife environment list` ; do
	knife environment show -Fj $i > environments/$i.json
done

# roles
mkdir roles
for i in `knife role list` ; do
	knife role show -Fj $i > roles/$i.json
done

# XXX back up db, maybe?

# make tarball and clean up
cd ..
tar cf - $DIRNAME | gzip -9 > $DIRNAME.tar.gz
rm -rf $DIR
echo $DIR.tar.gz created

# homedir
if [ "-h" = "$2" ] ; then
	tar cf - ~ | gzip -9 > `whoami`.tar.gz
	echo  /tmp/`whoami`.tar.gz is created
fi


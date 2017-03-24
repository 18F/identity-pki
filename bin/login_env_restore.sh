#!/bin/sh
#
# This script restores from a tarball created by the backup script.
#

usage() {
	echo "usage:   $0 <env> <envbackupfile> <databagsecretfile>"
	echo "example: $0 tf envbackup-tf-2017-03-17-2330.tar.gz ~/.chef/tf-databag.key"
}

if [ -z "$1" -o ! -f "$2" -o ! -f "$3" ] ; then
	usage
	exit 1
fi

gunzip -c $2 | (cd /tmp && tar xpf -)
DIR=`echo $2 | sed 's/.tar.gz$//'`
cd /tmp/$DIR


# databag
knife data bag create config --secret-file $3
knife data bag from file config config_app_databag.json --secret-file $3

# users
knife data bag create users
for i in `ls users` ; do
	knife data bag from file users users/$i
done

# certs
cat idp_letsencryptdir.tar.gz | ssh -q ubuntu@idp1-0 "cd / ; sudo tar zxpf -"

# environments
for i in `ls environments` ; do
	knife environment from file $i
done

# roles
for i in `ls roles` ; do
	knife role from file $i
done

# XXX restore db, maybe?

# clean up
cd ..
rm -rf $DIR


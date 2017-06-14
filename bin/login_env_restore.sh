#!/bin/sh
#
# This script restores from a tarball created by the backup script.
#
usage() {
  echo "usage:   \"$0\" <env> <envbackupfile> <databagsecretfile>"
  echo "example: \"$0\" tf envbackup-tf-2017-03-17-2330.tar.gz ~/.chef/tf-databag.key"
}

if [ -z "$1" ] || [ ! -f "$2" ] || [ ! -f "$3" ] ; then
  usage
  exit 1
fi

gunzip -c "$2" | (cd /tmp && tar xpf -)
DIR=$(echo "$2" | sed 's/.tar.gz$//')
cd "$DIR" || exit

# databag
knife data bag create config --secret-file "$3"
knife data bag from file config config_app_databag.json --secret-file "$3"

# users
knife data bag create users
for i in users/* ; do
  knife data bag from file users "$i"
done

# environments
for i in environments/* ; do
  knife environment from file "$i"
done

# roles
for i in roles/* ; do
  knife role from file "$i"
done

# XXX restore db, maybe?

# clean up
cd .. || exit
rm -rf "$DIR"

#!/bin/sh

# define usage function
usage() {
  echo "usage:  $0 <env> <username>"
  exit 1
}

# check to assure that required arguments exist
#   -z assures that the variable is set
#   -o is used for additonal arguments in the condition)
if [ -z $1 -o -z $2 ] ; then
  echo "required argument not found, you must provide an environment and username"
  usage
fi

# rsync local repo (excluding .git folder) to your user's home folder on the jumpbox
rsync -auvq --exclude='.git' . ${2}@jumphost.${1}.login.gov:

# define list of files to compress in an archive
FILES="
 .chef/knife-$1.rb
 .chef/$1-databag.key
 .chef/$1-login-dev-validator.pem
 .chef/$2-$1.pem
 .env/$1.sh
"

# change to home directory since above files are assumed to be in your user's local home folder
cd ~

# check to make sure that each file exists (-f checks for file presence, ! negates the condition)
for i in $FILES ; do
  if [ ! -f "$i" ] ; then
    echo "required file not found. This requires the following files to be in place:\n ${FILES}"
    usage
  fi
done

# generate timestamp to use for unique filenames
TIMESTAMP=`date "+%Y%m%d%H%M%S"`

# create var for archive filename
ARCHIVE_FILENAME="login-conf.${TIMESTAMP}.tgz"

# remove any archives with the same name
rm -f /tmp/${ARCHIVE_FILENAME}
# tar and gunzip the list of files and name using the PID of the script ($$)
tar czf /tmp/${ARCHIVE_FILENAME} $FILES
# copy archive to jumphost user's home folder
scp -q /tmp/${ARCHIVE_FILENAME} ${2}@jumphost.${1}.login.gov:.
# remove the local copy of the archive
rm -f /tmp/${ARCHIVE_FILENAME}

# build remote commands string
#  - extract the archive
RC="tar xzpf ${ARCHIVE_FILENAME};"
#  - delete the archive
RC="$RC rm ${ARCHIVE_FILENAME};"
#  - create a .ssh directory and do not fail if one already exists (-p)
RC="$RC mkdir -p .ssh;"
#  - set proper perms on the .ssh directory
RC="$RC chmod 700 .ssh;"

#  - add github.com host key to known_hosts file
# RC="$RC ssh-keyscan -H github.com >> .ssh/known_hosts;"
#  - clone the identity-devops repo
# RC="$RC git clone git@github.com:18F/identity-devops.git /tmp;"

#  - create a new symlink to the correct env
RC="$RC ln -fs .chef/knife-$1.rb .chef/knife.rb;"

# execute remote commands on the jumphost
ssh -q -A ${2}@jumphost.${1}.login.gov ${RC}

# create unique name for tmp ssh config
SSH_CONFIG_FILENAME="login-ssh.${TIMESTAMP}.config"

# remove tmp ssh config file if it already exists
rm -f /tmp/${SSH_CONFIG_FILENAME}

# add contents to tmp ssh config
cat <<EOF >/tmp/${SSH_CONFIG_FILENAME}
Host *
    User ubuntu
EOF

# copy .ssh config to jumpbox users's .ssh folder
scp -q /tmp/${SSH_CONFIG_FILENAME} ${2}@jumphost.${1}.login.gov:.ssh/config

# remove local tmp ssh config
rm -f /tmp/${SSH_CONFIG_FILENAME}

echo "\nIf you see no errors above then SUCCESS!\n\nNOTE: you will probably need to edit .chef/knife.rb and .env/$1.sh to have proper paths in it\n"

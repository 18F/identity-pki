#!/bin/sh
usage() {
    echo "usage:  $0 <env> <jumphost> <username>"
    exit 1
}
if [ -z "$1" -o -z "$2" -o -z "$3"] ; then
    usage
fi
FILES="
 .chef/knife-$1.rb
 .chef/$1-databag.key
 .chef/$1-login-dev-validator.pem
 .chef/$3-$1.pem
 ./$1-env.sh
"
cd ~
for i in $FILES ; do
    if [ ! -f $i ] ; then
        usage
    fi
done
rm -f /tmp/$$.tar.gz
tar cf - $FILES | gzip -9 > /tmp/$$.tar.gz
scp /tmp/$$.tar.gz $2:.
rm -f /tmp/$$.tar.gz
ssh -A $2 "tar zxpf $$.tar.gz ; rm $$.tar.gz ; mkdir .ssh ; chmod 700 .ssh ; git clone git@github.com:18F/identity-devops.git ; rm -f .chef/knife.rb ; ln -s .chef/knife-$1.rb .chef/knife.rb"
rm -f /tmp/$$.config
cat <<EOF >/tmp/$$.config
Host *
    User ubuntu
EOF
scp /tmp/$$.config $2:.ssh/config
rm -f /tmp/$$.config
echo "XXX:  you will probably need to edit .chef/knife.rb and $1-env.sh to have proper paths in it"

#!/bin/sh -x

if [ -f /root/login-dev-validator.pem ] ; then
	echo "chef-server already set up!"
	exit 0
fi

# copy stuff to the proper place/ownership/perms
mkdir /root/.chef
mkdir /home/ubuntu/.chef
chmod 700 /root/.chef
chmod 700 /home/ubuntu/.chef
cp knife.rb /root/.chef/
cp knife.rb /home/ubuntu/.chef/
rm ./knife.rb
cp id_rsa_deploy /root/id_rsa_deploy
chmod 600 /root/id_rsa_deploy
rm ./id_rsa_deploy

# set the hostname so that the SSL certs will be properish
hostname chef.login.gov.internal
echo "127.0.0.1 chef.login.gov.internal" >> /etc/hosts

# make sure we have curl
apt-get update
apt-get -y install build-essential curl libffi-dev

curl -s "https://packages.chef.io/files/stable/chef-server/12.13.0/ubuntu/14.04/chef-server-core_12.13.0-1_amd64.deb" -o "/tmp/chef-server.deb"

# install the chef-server deb
dpkg -i /tmp/chef-server.deb || exit 1

# start the chef-server up
chef-server-ctl reconfigure || exit 1

# Set up an admin user
chef-server-ctl user-create admin Admin User dummy@login.gov '${chef_pw}' --filename /root/admin.pem || exit 1

# set up the org
chef-server-ctl org-create login-dev 'Login.gov' --association_user admin --filename /root/login-dev-validator.pem || exit 1

# create jenkins user
chef-server-ctl user-create jenkins Jenkins User dummy+jenkins@login.gov '${chef_pw}' --filename /root/jenkins.pem
chef-server-ctl org-user-add login-dev jenkins


# make sure we trust the cert
cat >>/etc/hosts <<EOF

127.0.0.1 chef.login.gov.internal

EOF
export PATH=$PATH:/opt/chef/embedded/bin:/opt/opscode/embedded/bin
knife ssl fetch -c /root/.chef/knife.rb
su - root -c "knife ssl fetch -c /root/.chef/knife.rb"

# slurp in the chef repo from identity-devops
apt-get -y install git
cat >/root/.ssh/config <<EOF
Host github.com
	StrictHostKeyChecking no
	IdentityFile /root/id_rsa_deploy
EOF
git clone git@github.com:18F/identity-devops.git
cd identity-devops
git checkout ${chef_repo_gitref}

# make sure we have all the gems we need
bundle install

# upload stuff here
berks
berks upload --ssl-verify=false
echo "Y" | knife backup restore roles environments -D kitchen -c /root/.chef/knife.rb
berks apply ${env_name} --ssl-verify=false
# databags?  XXX have template to encrypt.

echo completed chef-server setup


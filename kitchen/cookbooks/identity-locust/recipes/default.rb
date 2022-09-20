#
# Cookbook Name:: identity-locust
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# TODO needs more hardening
package 'landscape-common' do
  action :purge
end

package 'python-pip-whl' do 
  action :remove
end

package %w(python3 python3-dev python3-pip libssl-dev libffi-dev)

# make python 3 default
execute 'update-alternatives --install /usr/bin/python python /usr/bin/python2.7 1'
execute 'update-alternatives --install /usr/bin/python python /usr/bin/python3.6 2'

# upgrade pip
execute 'python3 -m pip install --upgrade pip'

# install newer version of awscli/botocore to avoid docevents failures
# https://github.com/boto/boto3/issues/2596
execute 'python3 -m pip install --upgrade awscli>=1.18.140'
directory '/var/log/loadtest' do
  owner 'root'
  group 'users'
  mode 0775
end

git '/etc/login.gov/repos/identity-loadtest' do
  repository 'https://github.com/18F/identity-loadtest.git'
  revision "#{node['identity-locust']['branch']}"
  action :sync
end

execute 'install_locust' do
  cwd '/etc/login.gov/repos/identity-loadtest'
  command 'pip3 install -r requirements.txt'
end

cookbook_file '/usr/local/bin/id-locust' do
  source 'id-locust'
  owner 'root'
  group 'root'
  mode '0755'
end

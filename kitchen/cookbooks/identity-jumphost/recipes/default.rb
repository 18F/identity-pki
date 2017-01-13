#
# Cookbook Name:: identity-jumphost
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# add users.  Users should have the environment as a group in their groups list
# XXX need to decrypt the users databag for this to work
# XXX should remove ssh_keys from runlist too once this works, maybe make it a jumphost role
include_recipe 'users'
users_manage node.chef_environment

# add berkshelf and terraform
include_recipe 'login_dot_gov::ruby'
gem_package 'berkshelf' do
  gem_binary "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/gem"
end
include_recipe 'terraform'

# terraform needs this dir to be writable
directory '/usr/local/src' do
  mode '1777'
end

# set up AWS cli
package 'python2.7'
package 'python-pip'
execute 'pip install awscli'

# set up proxy
include_recipe 'squid'


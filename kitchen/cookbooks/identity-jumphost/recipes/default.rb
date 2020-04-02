#
# Cookbook Name:: identity-jumphost
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# Install postgresql-client so that Redshift may be reached from the jumphost
case node[:platform_version]
when '16.04'
  package 'postgresql-client-9.5'
when '18.04'
  package 'postgresql-client-10'
else
  raise "Unexpected platform_version: #{node[:platform_version].inspect}"
end

# TODO needs more hardening
package 'landscape-common' do
  action :purge
end

# facilitate interactive testing by originating connections from jumphost.
#  you will need to port-forward via SSH to reach the proxy and
#  define databags for host and url ACLs
include_recipe 'squid'

# always lock down auto scaled instances
lockdown = node.fetch('login_dot_gov').fetch('lockdown')
if node.fetch('provisioner').fetch('name') == 'cloud-init' && node.chef_environment == 'prod'
  lockdown = true
end

# 'lockdown' variable controls SSHD security settings like 'DenyUsers'
template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  mode  '0600'
  notifies :run, 'execute[restart_sshd]'
  variables({
    :lockdown => lockdown,
    :eip => node['cloud']['public_ipv4'],
    :monitor_port => node.fetch('identity-jumphost').fetch('ssh-health-check-port')
  })
end

# standardize host_keys across all instances
#  NOTICE: dsa removed per ssh-audit (https://github.com/arthepsy/ssh-audit)
#file '/etc/ssh/ssh_host_dsa_key' do
#
if node.fetch('identity-jumphost').fetch('retrieve-ssh-host-keys')
  file '/etc/ssh/ssh_host_ecdsa_key' do
    owner	'root'
    group 'root'
    mode	'600'
    content ConfigLoader.load_config(node, 'jumphost/ssh_host_ecdsa_key')
    notifies :run, 'execute[restart_sshd]'
    sensitive true
  end

  file '/etc/ssh/ssh_host_rsa_key' do
    owner	'root'
    group 'root'
    mode	'600'
    content ConfigLoader.load_config(node, 'jumphost/ssh_host_rsa_key')
    notifies :run, 'execute[restart_sshd]'
    sensitive true
  end

  file '/etc/ssh/ssh_host_ed25519_key' do
    owner 'root'
    group 'root'
    mode  '600'
    content ConfigLoader.load_config(node, 'jumphost/ssh_host_ed25519_key')
    notifies :run, 'execute[restart_sshd]'
    sensitive true
  end
end

# clean out obsolete public keys
# if need to regen:
#   ssh-keygen -yf <private_file> > <pub_file>
Dir["/etc/ssh/{ssh_host_*_key.pub}"].each do |path|
  file ::File.expand_path(path) do
    action :delete
  end
end

execute 'restart_sshd' do
  command 'service ssh reload'
  action :nothing
end

case node[:platform_version]
when '16.04'
  template '/etc/network/interfaces.d/lo:1.cfg' do
    source 'lo:1.cfg.erb'
    variables({
      :eip => node['cloud']['public_ipv4']
    })
  end
  
  execute 'ifdown lo:1 ; ifup lo:1'
end

# drop in locust repo and binary for load testing
if node.fetch('identity-jumphost').fetch('loadtest').fetch('enabled')

  include_recipe 'login_dot_gov::python3'

  directory '/var/log/loadtest' do
    owner 'root'
    group 'users'
    mode 0775
  end

  git '/etc/login.gov/repos/identity-loadtest' do
    repository 'https://github.com/18F/identity-loadtest.git'
    revision "#{node['identity-jumphost']['loadtest']['branch']}"
    action :sync
  end

  execute 'install_locust' do
    cwd '/etc/login.gov/repos/identity-loadtest/load_testing'
    command 'pip3 install -r requirements.txt'
  end

  cookbook_file '/usr/local/bin/id-locust' do
    source 'id-locust'
    owner 'root'
    group 'root'
    mode '0755'
  end
end

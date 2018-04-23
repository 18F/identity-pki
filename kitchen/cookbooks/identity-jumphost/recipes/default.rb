#
# Cookbook Name:: identity-jumphost
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

# Install postgresql-client so that Redshift may be reached from the jumphost
package 'postgresql-client-9.5'

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

template '/etc/network/interfaces.d/lo:1.cfg' do
  source 'lo:1.cfg.erb'
  variables({
    :eip => node['cloud']['public_ipv4']
  })
end

execute 'ifdown lo:1 ; ifup lo:1'

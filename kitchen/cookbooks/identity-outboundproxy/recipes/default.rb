#
# Cookbook Name:: identity-outboundproxy
# Recipe:: default
#
# Copyright 2018, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

#install squid
package 'squid'

#configure squid
template '/etc/squid/squid.conf' do
    source 'squid.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    notifies :restart, 'service[squid]', :delayed
end

template '/etc/squid/domain-whitelist.conf' do
    source 'domain-whitelist.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
    notifies :restart, 'service[squid]', :delayed
end

template '/etc/squid/ip-whitelist.conf' do
    source 'ip-whitelist.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
    notifies :restart, 'service[squid]', :delayed
end

service 'squid' do
    supports :restart => true, :reload => true
    action [:enable, :start]
end
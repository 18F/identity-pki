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

aws_vpc_cidr = Chef::Recipe::AwsMetadata.get_aws_vpc_cidr

#configure squid
template '/etc/squid/squid.conf' do
    source 'squid.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
        vpc_cidr: "#{aws_vpc_cidr}"
    })
    notifies :restart, 'service[squid]', :delayed
end

template '/etc/squid/domain-whitelist.conf' do
    source 'domain-whitelist.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables ({
        identity_pivcac_service: "pivcac.#{node.chef_environment}.#{domain_name}"
    })
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
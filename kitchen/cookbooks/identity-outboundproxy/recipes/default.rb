#
# Cookbook Name:: identity-outboundproxy
# Recipe:: default
#
# Copyright 2018, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#
# Create array to hold the dynamic domain values
push_notification_domains = []

if node.fetch('identity-outboundproxy').fetch('use_dashboard_dynamic_updates')
    # Create array to store push notification urls from JSON
    json_push_notification_urls = []
    # Create array to store push notification urls for pushing
    push_notification_urls = []

    response = Chef::HTTP.new("https://dashboard.#{node.chef_environment}.identitysandbox.gov")  
    sp = response.get('/api/service_providers') 
    response_json = JSON.parse(sp) 
    response_json.each do |service_provider_config|
        json_push_notification_url = service_provider_config['push_notification_url']
        unless json_push_notification_url.nil? || json_push_notification_url.empty?
            push_notification_urls << service_provider_config['push_notification_url']
        end
    end

    # Split push_notification_url into ip and domains and localhost
    # Then grab each push_notification_url and put in an array
    ip_address_regex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
    push_notification_urls.each do |url|
        uri = URI.parse(url)
        if !uri.host.match(ip_address_regex) and !uri.host.match('localhost') and uri.scheme.match('https')
            # if not ip address or local host push hostnames
            push_notification_domains << uri.host
        end
    end
end

#install squid
package 'squid'

aws_vpc_cidr = Chef::Recipe::AwsMetadata.get_aws_vpc_cidr

domain_name = node.fetch('login_dot_gov').fetch('domain_name')

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

template '/etc/squid/domain-allowlist.conf' do
    source 'domain-allowlist.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
    variables ({
        identity_idp: ".#{domain_name}",
        push_notification_domains: push_notification_domains
    })
    notifies :restart, 'service[squid]', :delayed
end

template '/etc/squid/domain-denylist.conf' do
    source 'domain-denylist.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
    notifies :restart, 'service[squid]', :delayed
end

template '/etc/squid/ip-allowlist.conf' do
    source 'ip-allowlist.conf.erb'
    mode '0644'
    owner 'root'
    group 'root'
    notifies :restart, 'service[squid]', :delayed
end

service 'squid' do
    supports :restart => true, :reload => true
    action [:enable, :start]
end
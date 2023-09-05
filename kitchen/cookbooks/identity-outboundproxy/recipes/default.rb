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
    # Create array to store push notification urls for pushing
    push_notification_urls = []

    begin
        response = Chef::HTTP.new("https://dashboard.#{node.chef_environment}.identitysandbox.gov")
        sp = response.get('/api/service_providers') 
        response_json = JSON.parse(sp)
        response_json.each do |service_provider_config|
            json_push_notification_url = service_provider_config['push_notification_url']
            unless json_push_notification_url.nil? || json_push_notification_url.empty?
                push_notification_urls << service_provider_config['push_notification_url']
            end
        end
    rescue
        Chef::Log.warn("identity-outboundproxy: Failed to get push notification URLs from https://dashboard.#{node.chef_environment}.identitysandbox.gov - SKIPPING")
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

aws_vpc_cidr = (Chef::Recipe::AwsMetadata.get_aws_all_vpc_cidr).tr("\n", " ")
aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
domain_name = node.fetch('login_dot_gov').fetch('domain_name')

# Find alternative domain allowlists
# TODO: We use this same pattern in runner.rb. Refactor into a lib?
resource = Aws::EC2::Resource.new(region: Chef::Recipe::AwsMetadata.get_aws_region)
instance = resource.instance(Chef::Recipe::AwsMetadata.get_aws_instance_id)
valid_tags = [
  'proxy_for',
  'gitlab_hostname'
]
instance.tags.each do |tag|
  if valid_tags.include? tag.key
    node.run_state[tag.key] = tag.value
  end
end

if node.run_state['gitlab_hostname'] == nil
    gitlab_url = "gitlab.#{node.chef_environment}.#{domain_name}"
else
    gitlab_url = node.run_state['gitlab_hostname']
end

template '/etc/squid/domain-allowlist.conf' do
    source ["default/#{node.run_state['proxy_for']}-domain-allowlist.conf.erb", 'default/domain-allowlist.conf.erb']
    mode '0644'
    owner 'root'
    group 'root'
    variables ({
        identity_idp: ".#{domain_name}",
        push_notification_domains: push_notification_domains,
        gitlab_url: gitlab_url,
        aws_account_id: aws_account_id,
        aws_region: aws_region,
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
end

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

execute 'squid_parse' do
    command 'squid -k parse'
end

execute 'squid_debug' do
    command 'squid -k debug'
end

execute 'enable_squid_apparmor' do
    command 'aa-enforce /etc/apparmor.d/usr.sbin.squid'
    notifies :restart, 'service[squid]', :delayed
end

service 'squid' do
    supports :restart => true, :reload => true
    action [:enable, :start]
end

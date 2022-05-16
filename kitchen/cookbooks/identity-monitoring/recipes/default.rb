#
# Cookbook Name:: identity-monitoring
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

node.default['newrelic_infra']['config']['license_key'] = ConfigLoader.load_config(node, "newrelic_infra_license_key", common: true)

if node.fetch('login_dot_gov').fetch('http_proxy')
  node.default['newrelic_infra']['config']['proxy'] = node.fetch('login_dot_gov').fetch('http_proxy')
end

node.default['newrelic_infra']['config']['collector_url'] = 'https://gov-infra-api.newrelic.com'
node.default['newrelic_infra']['config']['identity_url'] = 'https://gov-identity-api.newrelic.com'
node.default['newrelic_infra']['config']['command_channel_url'] = 'https://gov-infrastructure-command-api.newrelic.com'
node.default['newrelic_infra']['apt']['action'] = :nothing

node.default['newrelic_infra']['config']['custom_attributes'] = {
  'lg_env' => node.chef_environment,
  'lg_domain' => node.fetch('login_dot_gov').fetch('domain_name'),
  'lg_role' => node.fetch('roles').first || 'unknown',
}

include_recipe 'newrelic-infra'

# kinda a terrible hack until the newrelic people fix their cookbook
directory '/var/run/newrelic-infra' do
	owner 'newrelic_infra'
	not_if { Dir.exist?('/var/run/newrelic-infra') }
end
directory '/tmp/nr-integrations' do
	owner 'newrelic_infra'
	not_if { Dir.exist?('/tmp/nr-integrations') }
end

cookbook_file '/etc/systemd/system/newrelic-infra.service' do
	mode '0644'
	source 'newrelic-infra.service'
	owner 'root'
	group 'root'
	action :create
	notifies :run, 'execute[reload_systemd]', :immediately
end

execute 'reload_systemd' do
	command "chown -R newrelic_infra: /tmp/nr-integrations /var/db/newrelic-infra /var/run/newrelic-infra ; systemctl daemon-reload ; systemctl restart newrelic-infra"
	action :nothing
end

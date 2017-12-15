#
# Cookbook Name:: identity-monitoring
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

node.default['newrelic_infra']['config']['license_key'] = ConfigLoader.load_config(node, "newrelic_infra_license_key", common: true)

node.default['newrelic_infra']['config']['custom_attributes'] = {
  'lg_env' => node.chef_environment,
  'lg_domain' => node.fetch('login_dot_gov').fetch('domain_name'),
  'lg_role' => node.roles.first || 'unknown',
}

include_recipe 'newrelic-infra'


#
# Cookbook Name:: identity-monitoring
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

node.default['newrelic_infra']['config']['license_key'] = ConfigLoader.load_config(node, "newrelic_infra_license_key", common: true)

include_recipe 'newrelic-infra'


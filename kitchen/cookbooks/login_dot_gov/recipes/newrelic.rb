node.default['newrelic']['server_monitoring']['hostname'] = node['set_fqdn']
node.default['newrelic']['server_monitoring']['license'] = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]['newrelic_license_key']
include_recipe "newrelic"


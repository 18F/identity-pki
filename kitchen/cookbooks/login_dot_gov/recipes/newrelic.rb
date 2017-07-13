node.default['newrelic']['server_monitoring']['hostname'] = node['set_fqdn']
node.default['newrelic']['server_monitoring']['license'] = ConfigLoader.load_config(node, "newrelic_license_key")
include_recipe "newrelic"

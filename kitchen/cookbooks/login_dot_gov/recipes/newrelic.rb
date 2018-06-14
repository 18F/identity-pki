node.default['newrelic']['server_monitoring']['hostname'] = node['set_fqdn']
node.default['newrelic']['server_monitoring']['license'] = ConfigLoader.load_config(node, "newrelic_license_key")

if node.fetch('login_dot_gov').fetch('http_proxy')
  node.default['newrelic']['server_monitoring']['proxy'] = node.fetch('login_dot_gov').fetch('http_proxy')
end

include_recipe "newrelic"

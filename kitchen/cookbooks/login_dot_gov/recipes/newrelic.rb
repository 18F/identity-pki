node.default['newrelic']['server_monitoring']['hostname'] = node['set_fqdn']
node.default['newrelic']['server_monitoring']['license'] = ConfigLoader.load_config(node, "newrelic_license_key")

if ENV['HTTP_PROXY']
    node.default['newrelic']['server_monitoring']['proxy'] = ENV['HTTP_PROXY']
end

include_recipe "newrelic"

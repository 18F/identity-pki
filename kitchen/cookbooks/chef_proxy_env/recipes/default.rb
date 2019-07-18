# frozen_string_literal: true

#
# Cookbook:: chef_proxy_env
# Recipe:: default
#

# Read proxy settings from files set in attribute locations and set on
# environment and global chef config.

Chef::Log.info('chef_proxy_env: Loading proxy configuration from files')

proxy_config = {}

['http_proxy', 'https_proxy', 'no_proxy'].each do |key|
  source_file = node.fetch('chef_proxy_env').fetch('config_files').fetch(key)
  begin
    value = ::File.read(source_file)
  rescue StandardError => err
    Chef::Log.error("chef_proxy_env: Failed to read proxy config: #{err}")
    raise
  end

  # treat empty string as unset
  value = value.strip
  value = nil if value.empty?

  proxy_config[key] = value
end

# We don't set any resources, so use warn to be sure it's visible in logs
Chef::Log.warn("chef_proxy_env: Setting env vars: #{proxy_config.inspect}")

proxy_config.each_pair do |key, value|
  # Assert that we can parse the HTTP(S) proxies as a URI
  if value && ['http_proxy', 'https_proxy'].include?(key)
    URI.parse(value)
  end

  Chef::Log.debug("chef_proxy_env: Set ENV[#{key.inspect}] = #{value.inspect}")
  Chef::Log.debug("chef_proxy_env: Set Chef::Config.#{key} = #{value.inspect}")
  ENV[key] = value
  Chef::Config.public_send(key + '=', value)
end

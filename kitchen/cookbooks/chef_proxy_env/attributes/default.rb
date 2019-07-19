# frozen_string_literal: true

# Default attributes specifying the file paths for setting chef proxy
# configuration. Feel free to override these from role/env config.

node.default['chef_proxy_env']['config_files']['http_proxy']  = '/etc/chef/proxy_env/http_proxy'
node.default['chef_proxy_env']['config_files']['https_proxy'] = '/etc/chef/proxy_env/https_proxy'
node.default['chef_proxy_env']['config_files']['no_proxy']    = '/etc/chef/proxy_env/no_proxy'

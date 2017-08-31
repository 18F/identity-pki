#
# Cookbook:: config_loader
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Encrypted data bag item
file '/etc/slackwebhook' do
  content ConfigLoader.load_config(node, 'slackwebhook')
end

# Getting a JSON file
file '/etc/elk_users' do
  content ConfigLoader.load_json(node, 'elk_htpasswd.json', common: true).keys.join(" ")
end

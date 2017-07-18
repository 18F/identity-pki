#
# Cookbook:: config_loader
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# Encrypted data bag item
file '/etc/slackwebhook' do
  content ConfigLoader.load_config(node, 'slackwebhook')
end

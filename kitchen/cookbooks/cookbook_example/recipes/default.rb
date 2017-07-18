#
# Cookbook:: cookbook_example
# Recipe:: default
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# https://github.com/sethvargo/chefspec#mocking-out-environments
# Config set in mocked out environment
file '/etc/terraform-version' do
  content node['terraform']['version']
end

# Encrypted data bag item
file '/etc/slackwebhook' do
  content ConfigLoader.load_config(node)['slackwebhook']
end

# Normal data bag item
file '/etc/usercomment' do
  content data_bag_item('users', 'test')['comment']
end

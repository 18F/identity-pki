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

# https://github.com/sethvargo/chefspec#data-bag--data-bag-item
# Encrypted data bag item
# This doesn't work yet with integration tests.  See
# http://atomic-penguin.github.io/blog/2013/06/07/HOWTO-test-kitchen-and-encrypted-data-bags/.
#file '/etc/slackwebhook' do
  #content Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]['slackwebhook']
#end

# Normal data bag item
file '/etc/usercomment' do
  content data_bag_item('users', 'test')['comment']
end

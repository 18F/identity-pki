#
# Cookbook:: service_discovery
# Recipe:: register
#
# Copyright:: 2017, The Authors, All Rights Reserved.

ruby_block 'register this instance' do
  block do
    ServiceDiscovery.register(node)
  end
  action :run
end

#
# Cookbook:: service_discovery
# Recipe:: test_publish_certificate
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# NOTE: This cookbook is only for test purposes.  Consumers should use the
# library directly in their own resource.

publish_certificate 'Publish my certificate with a custom suffix' do
  cert_path node['service_discovery']['cert_path']
  suffix "legacy"
end

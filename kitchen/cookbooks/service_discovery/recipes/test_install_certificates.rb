#
# Cookbook:: service_discovery
# Recipe:: test_install_certificates
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# NOTE: This cookbook is only for test purposes.  Consumers should use the
# library directly in their own resource.

# This is not part of the test, but needed to check that we named the
# certificates correctly.
file '/etc/canonical_hostname' do
  content CanonicalHostname.get_hostname
end

directory '/etc/trusted_nodes'

install_certificates 'Installing base certificates from registration' do
  service_tag_key 'service_tag'
  service_tag_value 'service-discovery-ec2-test-service'
  cert_user 'root'
  cert_group 'root'
  install_directory '/etc/trusted_nodes'
end

install_certificates 'Installing certificates with a custom prefix' do
  service_tag_key 'service_tag'
  service_tag_value 'service-discovery-ec2-test-service'
  cert_user 'root'
  cert_group 'root'
  install_directory '/etc/trusted_nodes'
  suffix 'legacy'
  notifies :create, 'file[/etc/should_be_notified]'
end

install_certificates 'Installing certificates with no change' do
  service_tag_key 'service_tag'
  service_tag_value 'service-discovery-ec2-test-service'
  cert_user 'root'
  cert_group 'root'
  install_directory '/etc/trusted_nodes'
  suffix 'legacy'
  notifies :create, 'file[/etc/should_not_be_notified]'
end

file '/etc/should_be_notified' do
  action :nothing
  content 'file contents'
end

file '/etc/should_not_be_notified' do
  action :nothing
  content 'file contents'
end

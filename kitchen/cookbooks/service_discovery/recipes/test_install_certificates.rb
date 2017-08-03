#
# Cookbook:: service_discovery
# Recipe:: test_install_certificates
#
# Copyright:: 2017, The Authors, All Rights Reserved.

# NOTE: This cookbook is only for test purposes.  Consumers should use the
# library directly in their own resource.

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
end

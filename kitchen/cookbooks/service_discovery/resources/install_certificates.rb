resource_name :install_certificates

property :name, String, default: 'Discover the given services and install their certificates in a directory'
property :service_tag_key, String
property :service_tag_value, String
property :cert_user, String, default: 'root'
property :cert_group, String, default: 'root'
property :install_directory, String
property :suffix, [String, nil], default: nil

default_action :install

action :install do
  services = ::Chef::Recipe::ServiceDiscovery.discover(node, service_tag_key, [service_tag_value])

  services.each do |service|

    # This suffix allows consumers to register with and discover non default
    # certificates.  This was only needed because we didn't want to change the
    # way we are currently generating elasticsearch certs using the java
    # keystore as that would require more work getting everything configured
    # properly (and it works now).
    if suffix.nil?
      cert_name = "#{service.fetch('hostname')}.crt"
      certificate = service.fetch('certificate')
    else
      cert_name = "#{service.fetch('hostname')}-#{suffix}.crt"
      certificate = Chef::Recipe::ServiceDiscovery.get_certificate(node, cert_name)
    end

    file "#{install_directory}/#{cert_name}" do
      content certificate
      owner cert_user
      group cert_group
      mode '0644'
    end
  end
end

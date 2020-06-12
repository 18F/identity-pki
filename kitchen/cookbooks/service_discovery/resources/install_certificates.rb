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
  services = ::Chef::Recipe::ServiceDiscovery.discover(node, new_resource.service_tag_key, [new_resource.service_tag_value])

  services.each do |service|

    # This suffix allows consumers to register with and discover non default
    # certificates.  This was only needed because we didn't want to change the
    # way we are currently generating elasticsearch certs using the java
    # keystore as that would require more work getting everything configured
    # properly (and it works now).
    if new_resource.suffix.nil?
      cert_name = "#{service.fetch('hostname')}.crt"
      certificate = service.fetch('certificate')
    else
      cert_name = "#{service.fetch('hostname')}-#{new_resource.suffix}.crt"
      certificate = Chef::Recipe::ServiceDiscovery.get_certificate(node, cert_name)
    end

    unless certificate.nil? or certificate.empty?
      file "#{new_resource.install_directory}/#{cert_name}" do
        content certificate
        owner new_resource.cert_user
        group new_resource.cert_group
        mode '0644'
      end
    end
  end
end

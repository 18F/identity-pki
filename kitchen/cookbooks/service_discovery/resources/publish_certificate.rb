resource_name :publish_certificate

property :name, String, default: 'Publish a local certificate to s3'
property :cert_path, String
property :suffix, [String, nil], default: nil

default_action :publish

action :publish do
  hostname = Chef::Recipe::CanonicalHostname.get_hostname

  # This suffix allows consumers to register with and discover non default
  # certificates.  This was only needed because we didn't want to change the way
  # we are currently generating elasticsearch certs using the java keystore as
  # that would require more work getting everything configured properly (and it
  # works now).
  s3_path = new_resource.suffix.nil? ? "#{hostname}.crt" : "#{hostname}-#{new_resource.suffix}.crt"

  log 'publishing certificate' do
    message "Publishing certificate: #{new_resource.cert_path} to s3 at #{s3_path}"
    level :info
  end

  Chef::Recipe::ServiceDiscovery.put_certificate(node, new_resource.cert_path, s3_path)
end

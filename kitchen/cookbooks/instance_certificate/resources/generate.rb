resource_name :generate

property :name, String, default: 'generate and install instance key and certificate'
property :cert_path, String, identity: true
property :key_path, String, identity: true
property :valid_days, Integer
property :regenerate_grace_seconds, Integer, default: 3600 * 24
property :subject, [String, nil], default: lazy { |_r| default_subject }
property :owner, String, default: 'root'
property :group, String, default: 'root'
property :_loaded_cert, OpenSSL::X509::Certificate

def default_subject
  "CN=#{::Chef::Recipe::CanonicalHostname.get_hostname}, OU=#{node.chef_environment}"
end


default_action :generate

load_current_value do
  current_value_does_not_exist! unless cert_path && ::File.exist?(cert_path)

  raw_cert = ::File.read(cert_path)
  cert = OpenSSL::X509::Certificate.new(raw_cert)

  _loaded_cert cert

  subject cert.subject.to_s
  valid_days(((cert.not_after - cert.not_before) / 3600 / 24).round)
end

action :generate do

  # Make sure the certificate directories exist
  directory ::File.dirname(new_resource.key_path)
  directory ::File.dirname(new_resource.cert_path)

  # Generate a new certificate by default
  regenerate = true

  new_resource.subject default_subject if new_resource.subject.nil?

  # If the X.509 subject has not changed and the cert is not expired, then
  # there is no need to regenerate
  if current_resource
    current_subject = current_resource._loaded_cert.subject
    new_subject = OpenSSL::X509::Name.parse(new_resource.subject)
    if current_subject == new_subject
      # check if cert is expired or will expire within regenerate_grace_seconds
      if Time.now + new_resource.regenerate_grace_seconds < current_resource._loaded_cert.not_after
        # existing cert is OK
        regenerate = false
      end
    end
  end

  if regenerate
    key, cert = ::Chef::Recipe::CertificateGenerator.generate_selfsigned_keypair(new_resource.subject, new_resource.valid_days)
    key_content = key.to_pem
    cert_content = cert.to_pem
    new_resource._loaded_cert cert
  else
    # leave unchanged
    key_content = nil
    cert_content = nil
  end

  file new_resource.key_path do
    content key_content
    mode '0700'
    sensitive true
    owner(owner)
    group(group)
  end

  file new_resource.cert_path do
    content cert_content
    mode '0644'
    owner(owner)
    group(group)
  end
end

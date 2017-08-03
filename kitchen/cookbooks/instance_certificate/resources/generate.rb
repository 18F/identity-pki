resource_name :generate

property :name, String, default: 'generate and install instance key and certificate'
property :cert_path, String
property :key_path, String
property :valid_days, Integer
property :subject, String

default_action :generate

action :generate do

  # Make sure the certificate directories exist
  directory ::File.dirname(node['instance_certificate']['key_path'])
  directory ::File.dirname(node['instance_certificate']['cert_path'])

  # If certificate exists, we want to check two things:
  #
  # 1. Has the subject changed (in an X509 aware way)
  # 2. Is the certificate expired
  regenerate = true
  if ::File.exist?(new_resource.cert_path)

    # Get the current certificate
    raw_cert = ::File.read(new_resource.cert_path)
    cert = OpenSSL::X509::Certificate.new(raw_cert)

    # Get the new subject in an X509 form
    if new_resource.subject.nil?
        new_cert_subject = nil
    else
        new_cert_subject = OpenSSL::X509::Name.parse(new_resource.subject)
    end

    # If the subjects match and the cert is not expired, do not regenerate
    if Time.now < cert.not_after && new_cert_subject == cert.subject
      regenerate = false
    end
  end

  if regenerate
    if subject.nil?
        subject "CN=#{::Chef::Recipe::CanonicalHostname.get_hostname}, OU=#{node.chef_environment}, O=login.gov, L=Washington, ST=District of Columbia, C=US"
    end
    key, cert = ::Chef::Recipe::CertificateGenerator.generate_selfsigned_keypair(subject, valid_days)

    file key_path do
      content key.to_pem
    end

    file cert_path do
      content cert.to_pem
    end
  end
end

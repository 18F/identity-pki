resource_name :publish_cert_and_chain

# This is a _very_ specific library, only meant to solve the problem of
# elasticsearch and elk publishing self signed certs to s3.
property :name, String, default: 'Publish the cert and chain of this ES node to s3.'
property :cert, String, required: true
property :cert_and_chain_path, String, required: true
property :chain, [String, nil], default: nil
property :suffix, String, required: true
property :owner, String, default: "root"

default_action :publish

action :publish do

  # XXX: This is a workaround for ELK, which currently only publishes its self
  # signed certificate, whereas ES was sharing both the cert and a ca chain that
  # chef generated.
  if chain
    cert_and_chain = ::File.read(cert) + ::File.read(chain)
  else
    cert_and_chain = ::File.read(cert)
  end

  file cert_and_chain_path do
    content cert_and_chain
    owner owner
    group owner
    mode '0644'
  end

  publish_certificate 'Publish my certificate with a custom suffix' do
    cert_path cert_and_chain_path
    suffix new_resource.suffix
  end
end

attributes = node.fetch('instance_certificate')

generate 'generate and install instance key and certificate' do
  key_path attributes.fetch('key_path')
  cert_path attributes.fetch('cert_path')
  subject attributes.fetch('subject') if attributes.include?('subject')
  valid_days attributes.fetch('valid_days')
end

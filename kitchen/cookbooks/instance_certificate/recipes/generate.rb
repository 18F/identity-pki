generate 'generate and install instance key and certificate' do
  key_path node['instance_certificate']['key_path']
  cert_path node['instance_certificate']['cert_path']
  subject node['instance_certificate']['subject']
  valid_days node['instance_certificate']['valid_days']
end

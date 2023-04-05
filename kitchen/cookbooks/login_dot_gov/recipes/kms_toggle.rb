# Add the enable and disable Cloudwatch KMS scripts

file '/usr/local/bin/id-disable-kms' do
  source 'id-disable-kms'
  owner 'root'
  group 'root'
  mode '0755'
end

file '/usr/local/bin/id-enable-kms' do
  source 'id-enable-kms'
  owner 'root'
  group 'root'
  mode '0755'
end

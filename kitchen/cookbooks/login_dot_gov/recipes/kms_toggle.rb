# Add the enable and disable Cloudwatch KMS scripts

cookbook_file '/usr/local/bin/id-disable-kms' do
  source 'id-cloudwatch-disable-kms'
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/usr/local/bin/id-enable-kms' do
  source 'id-cloudwatch-enable-kms'
  owner 'root'
  group 'root'
  mode '0755'
end

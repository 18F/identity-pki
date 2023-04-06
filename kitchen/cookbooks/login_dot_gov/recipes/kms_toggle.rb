# Add the enable and disable Cloudwatch KMS scripts

cookbook_file '/usr/local/bin/id-disable-cloudwatch-kms' do
  source 'id-disable-cloudwatch-kms'
  owner 'root'
  group 'root'
  mode '0755'
end

cookbook_file '/usr/local/bin/id-enable-cloudwatch-kms' do
  source 'id-enable-cloudwatch-kms'
  owner 'root'
  group 'root'
  mode '0755'
end

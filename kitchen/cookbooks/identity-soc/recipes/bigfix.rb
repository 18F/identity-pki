# vars
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
bucket = "login-gov.secrets.#{aws_account_id}-#{aws_region}"
config_dir = '/etc/opt/BESClient'
version = node.fetch('identity-soc').fetch('bigfix').fetch('version')
agent_dpkg = "BESAgent-#{version}-ubuntu10.amd64.deb"

# setup agent dir
directory config_dir

# copy configs
cookbook_file "#{config_dir}/actionsite.afxm" do
  source 'actionsite.afxm'
end
cookbook_file "#{config_dir}/besclient.config" do
  source 'besclient.config'
end

# copy agent installer
execute "aws s3 cp s3://#{bucket}/common/#{agent_dpkg} /var/tmp/"

# install agent from dpkg
dpkg_package "/var/tmp/#{agent_dpkg}"

# enable and start
systemd_unit 'besclient' do
  action [:enable, :start]
end

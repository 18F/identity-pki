# vars
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
bucket = "login-gov.secrets.#{aws_account_id}-#{aws_region}"
bucket_path = '/common/soc_agents/bigfix'
etc_dir = '/etc/opt/BESClient'
var_dir = '/var/opt/BESClient'
version = node.fetch('identity-soc').fetch('bigfix').fetch('version')
agent_dpkg = "BESAgent-#{version}-debian6.amd64.deb"

# setup agent dirs
directory etc_dir
directory var_dir

# generate config
cookbook_file "#{var_dir}/besclient.config" do
  source 'besclient.config'
end

# copy agent installer and license
execute "aws s3 cp s3://#{bucket}#{bucket_path}/actionsite.afxm #{etc_dir}/"
execute "aws s3 cp s3://#{bucket}#{bucket_path}/#{agent_dpkg} /var/tmp/"

# install agent from dpkg
dpkg_package "/var/tmp/#{agent_dpkg}"

# enable and start
systemd_unit 'besclient' do
  action [:enable, :start]
end

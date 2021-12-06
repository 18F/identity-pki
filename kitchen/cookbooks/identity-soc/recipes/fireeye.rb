require 'json'

# vars
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
bucket = "login-gov.secrets.#{aws_account_id}-#{aws_region}"
install_directory = '/var/tmp/xagt'
server = node.fetch('identity-soc').fetch('fireeye').fetch('server')
version = node.fetch('identity-soc').fetch('fireeye').fetch('version')

deb_installer = "xagt_#{version}.ubuntu16_amd64.deb"
filename = "IMAGE_HX_AGENT_LINUX_#{version}.tgz"

# remove OSSEC
apt_package 'ossec-hids-agent' do
  action :remove
end

# copy agent installer
directory install_directory
execute "aws s3 cp s3://#{bucket}/common/#{filename} #{install_directory}/"

# untar + gzip
execute "tar xzvf #{install_directory}/#{filename} -C #{install_directory}/"

# install agent from dpkg
dpkg_package "#{install_directory}/#{deb_installer}"

proxy_config = {
  host: 'obproxy.login.gov.internal',
  port: 3128,
  type: 'manual',
  enabled: true,
  password: '',
  username: '',
  exclude_hosts: [],
  failed_retry_delay: 1200,
  exclude_local_hosts: false
}

ruby_block 'update serverlist servers' do
  block do
    # parse the config json and keep only the pubicly addressible server
    config = JSON.parse(File.read("#{install_directory}/agent_config.json"))
    config['serverlist']['servers'] = [{server: server}]
    config['proxy'] = proxy_config
    File.write("#{install_directory}/agent_config.json", JSON.dump(config))
  end
end

# import config
execute "/opt/fireeye/bin/xagt -i #{install_directory}/agent_config.json" do
  ignore_failure true
end

# enable and start
systemd_unit 'xagt' do
  action [:enable, :start]
end

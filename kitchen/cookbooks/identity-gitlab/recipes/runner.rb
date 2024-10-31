#
# Cookbook:: identity-gitlab
# Recipe:: runner
#

require 'aws-sdk-ec2'

include_recipe 'filesystem'

ruby_block 'Get the correct docker device' do
  block do
    block_devices = ['/dev/nvme1n1', '/dev/nvme2n1']
    default_block_device = '/dev/nvme1n1'
    block_devices.each do |device|
      cmd = Mixlib::ShellOut.new("file -s #{device} | grep data")
      cmd.run_command
      if cmd.exitstatus == 0
        default_block_device = device
        break
      end
    end
    node.run_state['identity_gitlab_default_docker_block_device'] = default_block_device
  end
  ignore_failure true
  action :run
end

filesystem 'docker' do
  fstype 'ext4'
  device lazy { "#{node.run_state['identity_gitlab_default_docker_block_device']}" }
  mount '/var/lib/docker'
  action [:create, :enable, :mount]
end

# The elastic stuff is causing deploys to take too long, so stop them and restart them at the end
execute 'stop_elastic_stuff' do
  command 'systemctl stop elastic-agent.service ; systemctl stop ElasticEndpoint.service'
  action :run
  notifies :run, 'execute[start_elastic_stuff]', :delayed
  ignore_failure true
end
execute 'start_elastic_stuff' do
  command 'systemctl start elastic-agent.service ; systemctl start ElasticEndpoint.service'
  action :nothing
  ignore_failure true
end

packagecloud_repo 'runner/gitlab-runner' do
  type 'deb'
  base_url 'https://packages.gitlab.com/'
end

package 'gitlab-runner' do
  version node['identity_gitlab']['gitlab_runner_version']
end

# install docker-credential-ecr-login so we can auth to ECR
# (from https://github.com/awslabs/amazon-ecr-credential-helper/releases)
cookbook_file '/usr/local/bin/docker-credential-ecr-login' do
  source 'docker-credential-ecr-login-0.7.1.linux-amd64'
  mode '0755'
  owner 'root'
  group 'root'
end

resource = Aws::EC2::Resource.new(region: Chef::Recipe::AwsMetadata.get_aws_region)
instance = resource.instance(Chef::Recipe::AwsMetadata.get_aws_instance_id)

valid_tags = [
  'gitlab_runner_pool_name',
  'allow_untagged_jobs',
  'is_it_an_env_runner',
  'gitlab_ecr_repo_accountid',
  'only_on_protected_branch',
  'gitlab_hostname',
  'gitlab_config_s3_bucket',
]

instance.tags.each do |tag|
  if valid_tags.include? tag.key
    node.run_state[tag.key] = tag.value
  end
end

aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
http_proxy = node['login_dot_gov']['http_proxy']
https_proxy = node['login_dot_gov']['https_proxy']
no_proxy = node['login_dot_gov']['no_proxy']
runner_name = node['hostname']
gitlab_ecr_registry = "#{node.run_state['gitlab_ecr_repo_accountid']}.dkr.ecr.#{aws_region}.amazonaws.com"

if node.run_state['gitlab_hostname'].nil?
  external_fqdn = "gitlab.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
else
  external_fqdn = node.run_state['gitlab_hostname']
end
external_url = "https://#{external_fqdn}"

if node.run_state['gitlab_config_s3_bucket'].nil?
  config_s3_bucket = "login-gov-#{node.chef_environment}-gitlabconfig-#{node.run_state['gitlab_ecr_repo_accountid']}-#{aws_region}"
else
  config_s3_bucket = node.run_state['gitlab_config_s3_bucket']
end
runner_token = shell_out("aws s3 cp s3://#{config_s3_bucket}/gitlab_runner_token -").stdout.chomp

if node.run_state['is_it_an_env_runner'] == 'true'
  # Only allow images in the */blessed repos.
  # To "bless" an image and move it into a blessed repo, use Google's `crane` util to
  # copy it from the automation-writeable repo while preserving the digest. For example:
  #
  # brew install crane
  # crane copy <account>.dkr.ecr.us-west-2.amazonaws.com/cd/env_deploy@sha256:42a373721c2c26[...] \
  #   <account>.dkr.ecr.us-west-2.amazonaws.com/cd/env_deploy/blessed

  node.run_state['runner_tag'] = node.environment + '-' + node.run_state['gitlab_runner_pool_name']
  node.run_state['ecr_accountid'] = node.run_state['gitlab_ecr_repo_accountid']
  node.run_state['allowed_services'] = ['']
  node.run_state['allowed_images'] = [
    "#{node['identity_gitlab']['production_aws_account_id']}.dkr.ecr.#{aws_region}.amazonaws.com/**/blessed@sha256:*",
    "#{node.run_state['ecr_accountid']}.dkr.ecr.#{aws_region}.amazonaws.com/**/blessed@sha256:*",
  ].uniq
else
  node.run_state['runner_tag'] = node.run_state['gitlab_runner_pool_name']
  node.run_state['ecr_accountid'] = aws_account_id
  node.run_state['allowed_services'] = []
  node.run_state['allowed_images'] = []
end

repohosts = [
  "#{node['identity_gitlab']['production_aws_account_id']}.dkr.ecr.#{aws_region}.amazonaws.com",
  "#{node.run_state['ecr_accountid']}.dkr.ecr.#{aws_region}.amazonaws.com",
].uniq
repolist = repohosts.map { |repohost| ',"' + repohost + '": "ecr-login"' }.join

directory '/etc/systemd/system/gitlab-runner.service.d'

template '/etc/systemd/system/gitlab-runner.service.d/http-proxy.conf' do
  source 'http-proxy.conf.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables({
    http_proxy: http_proxy,
    https_proxy: https_proxy,
    no_proxy: no_proxy,
  })
  notifies :run, 'execute[systemctl_daemon_config]', :immediately
end

template '/etc/systemd/system/gitlab-runner.service.d/aws-region.conf' do
  source 'aws-region.conf.erb'
  owner 'root'
  group 'root'
  mode '644'
  notifies :run, 'execute[systemctl_daemon_config]', :immediately
end

execute 'systemctl_daemon_config' do
  command 'systemctl daemon-reload'
  action :nothing
end

docker_service 'default' do
  action [:create]
  ipv6 false
  ipv6_forward false
  http_proxy http_proxy
  https_proxy https_proxy
  no_proxy no_proxy
  icc false
  log_level 'debug'
  live_restore true
  userland_proxy false
  misc_opts '--no-new-privileges'
  userns_remap 'default'
  default_ulimit 'nproc=16384:16384'
end

docker_network 'runner-net' do
  driver 'bridge'
end

template '/etc/gitlab-runner/runner-register.sh' do
  source 'runner-register.sh.erb'
  variables({
    http_proxy: http_proxy,
    https_proxy: https_proxy,
    no_proxy: no_proxy,
    external_url: external_url,
    runner_name: runner_name,
    runner_token: runner_token,
    gitlab_ecr_registry: gitlab_ecr_registry,
    repolist: repolist,
    aws_account_id: aws_account_id,
    aws_region: aws_region,
  })
  mode '755'
  sensitive true
  notifies :run, 'execute[configure_gitlab_runner]', :immediately
end

execute 'configure_gitlab_runner' do
  command '/etc/gitlab-runner/runner-register.sh'
  action :nothing
  sensitive false
  notifies :run, 'execute[restart_runner]', :immediately
end

execute 'remove_registration_script' do
  command '/bin/rm -f /etc/gitlab-runner/runner-register.sh'
end

group 'docker' do
  append true
  members ['gitlab-runner']
  action :modify
end

execute 'restart_runner' do
  command 'systemctl restart gitlab-runner'
  action :nothing
end

execute 'reload_runner' do
  command 'kill -HUP $(systemctl show --property MainPID --value gitlab-runner)'
  action :nothing
end

cron_d 'clear_docker_cache' do
  action :create
  predefined_value '@daily'
  command '/usr/share/gitlab-runner/clear-docker-cache'
end

# This is terrible, but it seems to be the only way to do this:
# https://gitlab.com/gitlab-org/gitlab-runner/-/issues/1539
# XXX If ever we figure out our concurrency issues, we can go back to 2 or more.
execute 'update_runner_concurrency' do
  command "sed -i \"s/^concurrent = .*/concurrent = #{node['identity_gitlab']['concurrency']}/\" /etc/gitlab-runner/config.toml"
  notifies :run, 'execute[reload_runner]', :immediately
end


# Get the unsigned image killer script going.
file '/root/image_signing.pub' do
  content ConfigLoader.load_config_or_nil(node, node['identity_gitlab']['image_signing_pubkey'], common: node['identity_gitlab']['image_signing_pubkey_common'])
  mode '0644'
  owner 'root'
  group 'root'
  only_if { node['identity_gitlab']['image_signing_verification'] && node.run_state['is_it_an_env_runner'] == 'true' }
end

template '/usr/local/bin/killunsignedimages.sh' do
  source 'killunsignedimages.sh.erb'
  mode '755'
  only_if { node['identity_gitlab']['image_signing_verification'] && node.run_state['is_it_an_env_runner'] == 'true' }
end

cron_d 'kill_unsigned_images' do
  action :create
  command '/usr/bin/flock -n /tmp/kill_unsigned_images /usr/local/bin/killunsignedimages.sh /root/image_signing.pub'
  only_if { node['identity_gitlab']['image_signing_verification'] && node.run_state['is_it_an_env_runner'] == 'true' }
end

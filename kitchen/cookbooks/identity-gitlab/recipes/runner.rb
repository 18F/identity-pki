#
# Cookbook Name:: identity-gitlab
# Recipe:: runner
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

require 'aws-sdk-ec2'

include_recipe 'filesystem'

filesystem 'docker' do
  fstype "ext4"
  device '/dev/nvme1n1'
  mount "/var/lib/docker"
  action [:create, :enable, :mount]
end

execute 'grab_gitlab_runner_repo' do
  command 'curl https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash'
  ignore_failure true
end

package 'gitlab-runner' do
  version "14.10.1"
end

# install docker-credential-ecr-login so we can auth to ECR
# (from https://github.com/awslabs/amazon-ecr-credential-helper/releases)
cookbook_file '/usr/local/bin/docker-credential-ecr-login' do
  source 'docker-credential-ecr-login-0.6.0.linux-amd64'
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
  'gitlab_hostname'
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

if node.run_state['gitlab_hostname'] == nil
  external_fqdn = "gitlab.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
else
  external_fqdn = node.run_state['gitlab_hostname']
end
external_url = "https://#{external_fqdn}"

if node.run_state['gitlab_ecr_repo_accountid'] == nil
  config_s3_bucket = "login-gov-#{node.chef_environment}-gitlabconfig-#{aws_account_id}-#{aws_region}"
else
  config_s3_bucket = "login-gov-#{node.chef_environment}-gitlabconfig-#{node.run_state['gitlab_ecr_repo_accountid']}-#{aws_region}"
end
runner_token = shell_out("aws s3 cp s3://#{config_s3_bucket}/gitlab_runner_token -").stdout.chomp

if node.run_state['is_it_an_env_runner'] == 'true'
  # only allow images with the proper digests, which are hardcoded into
  # the gitlab_env_runner_allowed_images file in the env secret bucket:
  #   s3://login-gov.secrets.<account>-us-west-2/<env>/gitlab_env_runner_allowed_images
  # Or in the common secret bucket, if the env secret does not exist:
  #   s3://login-gov.secrets.<account>-us-west-2/common/gitlab_env_runner_allowed_images
  # 
  # The file should look something like:
  #   <account>.dkr.ecr.us-west-2.amazonaws.com/cd/env_deploy@sha256:e04b3b710e76ff00dddd3d62029571fb40a2edeba6ffbda4fa80138c079264b1
  #   <account>.dkr.ecr.us-west-2.amazonaws.com/cd/env_test@sha256:e04b3b710e76ff00dddd3d62029571fb4feeddeba6ffbda4fa80138c079264b1
  #
  # You can find the digest by going to ECR in the AWS console and looking at the repo,
  # finding the build that you have approved, and then copying the digest for it.
  # They look like "sha256:2feedface4242424242<etc>"
  # 
  node.run_state['runner_tag'] = node.environment + '-' + node.run_state['gitlab_runner_pool_name']
  node.run_state['ecr_accountid'] = node.run_state['gitlab_ecr_repo_accountid']
  allowed_images = ConfigLoader.load_config_or_nil(node, "gitlab_env_runner_allowed_images")
  if allowed_images.nil?
    node.run_state['allowed_images'] = ConfigLoader.load_config(node, "gitlab_env_runner_allowed_images", common: true).chomp.split()
  else
    node.run_state['allowed_images'] = allowed_images.chomp.split()
  end
  node.run_state['allowed_services'] = [""]
else
  node.run_state['runner_tag'] = node.run_state['gitlab_runner_pool_name']
  node.run_state['ecr_accountid'] = aws_account_id
  # this actually allows all services/images if it is empty.  Otherwise, you can fill this with
  # images like "foo/bar:baz" or "foo@sha256-423f234f..." or whatever.
  node.run_state['allowed_images'] = []
  node.run_state['allowed_services'] = []
end

directory '/etc/systemd/system/gitlab-runner.service.d'

template '/etc/systemd/system/gitlab-runner.service.d/http-proxy.conf' do
  source 'http-proxy.conf.erb'
  owner 'root'
  group 'root'
  mode '644'
  variables ({
    http_proxy: http_proxy,
    https_proxy: https_proxy,
    no_proxy: no_proxy,
  })
  notifies :run, 'execute[systemctl_daemon_config]', :immediate
end

template '/etc/systemd/system/gitlab-runner.service.d/aws-region.conf' do
  source 'aws-region.conf.erb'
  owner 'root'
  group 'root'
  mode '644'
  notifies :run, 'execute[systemctl_daemon_config]', :immediate
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
  default_ulimit 'nproc=256:512'
end

docker_network 'runner-net' do
  driver 'bridge'
end

template '/etc/gitlab-runner/runner-register.sh' do
  source 'runner-register.sh.erb'
  variables ({
    http_proxy: http_proxy,
    https_proxy: https_proxy,
    no_proxy: no_proxy,
    external_url: external_url,
    runner_name: runner_name,
    runner_token: runner_token,
    gitlab_ecr_registry: gitlab_ecr_registry,
    aws_account_id: aws_account_id,
    aws_region: aws_region,
  })
  mode '755'
  sensitive true
  notifies :run, 'execute[configure_gitlab_runner]', :immediate
end

execute 'configure_gitlab_runner' do
  command '/etc/gitlab-runner/runner-register.sh'
  action :nothing
  sensitive true
  notifies :run, 'execute[restart_runner]', :immediate
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

cron_d 'clear_docker_cache' do
  action :create
  predefined_value '@daily'
  command '/usr/share/gitlab-runner/clear-docker-cache'
end

# This is terrible, but it seems to be the only way to do this:
# https://gitlab.com/gitlab-org/gitlab-runner/-/issues/1539
# XXX If ever we figure out our concurrency issues, we can go back to 2 or more.
execute 'update_runner_concurrency' do
  command 'sed -i "s/^concurrent = .*/concurrent = 1/" /etc/gitlab-runner/config.toml'
  notifies :run, 'execute[restart_runner]', :immediate
end

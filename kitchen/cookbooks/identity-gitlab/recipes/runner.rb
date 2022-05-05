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

package 'gitlab-runner'

cookbook_file '/usr/local/bin/docker-credential-ecr-login' do
  source 'docker-credential-ecr-login-0.6.0.linux-amd64'
  mode '0755'
  owner 'root'
  group 'root'
end

resource = Aws::EC2::Resource.new(region: Chef::Recipe::AwsMetadata.get_aws_region)

aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
config_s3_bucket = "login-gov-#{node.chef_environment}-gitlabconfig-#{aws_account_id}-#{aws_region}"
external_fqdn = "gitlab.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
external_url = "https://#{external_fqdn}"
http_proxy = node['login_dot_gov']['http_proxy']
https_proxy = node['login_dot_gov']['https_proxy']
instance = resource.instance(Chef::Recipe::AwsMetadata.get_aws_instance_id)
no_proxy = node['login_dot_gov']['no_proxy']
runner_name = node['hostname']
runner_token = shell_out("aws s3 cp s3://#{config_s3_bucket}/gitlab_runner_token -").stdout.chomp

valid_tags = [
  'gitlab_runner_pool_name',
  'allow_untagged_jobs',
]

instance.tags.each do |tag|
  if valid_tags.include? tag.key
    node.run_state[tag.key] = tag.value
  end
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

execute 'configure_gitlab_runner' do
  command <<-EOH
    gitlab-runner register \
    --non-interactive \
    --name "#{runner_name}" \
    --url "#{external_url}" \
    --registration-token "#{runner_token}" \
    --executor docker \
    --env HTTP_PROXY="#{http_proxy}" \
    --env HTTPS_PROXY="#{https_proxy}" \
    --env http_proxy="#{http_proxy}" \
    --env https_proxy="#{https_proxy}" \
    --env NO_PROXY="#{no_proxy}" \
    --env no_proxy="#{no_proxy}" \
    --env DOCKER_AUTH_CONFIG='{ \"credsStore\": \"ecr-login\"}' \
    --docker-image="#{aws_account_id}.dkr.ecr.#{aws_region}.amazonaws.com/ecr-public/docker/library/alpine:latest" \
    --run-untagged="#{node.run_state['allow_untagged_jobs']}" \
    --tag-list "#{node.run_state['gitlab_runner_pool_name']}" \
    --locked=false \
    --cache-shared \
    --cache-type s3 \
    --cache-path "#{node.chef_environment}" \
    --cache-s3-server-address s3.amazonaws.com \
    --cache-s3-bucket-name "login-gov-#{node.chef_environment}-gitlabcache-#{aws_account_id}-#{aws_region}" \
    --cache-s3-bucket-location "#{aws_region}" \
    --cache-s3-authentication_type iam \
    --access-level=not_protected \
    --docker-memory 4096m \
    --docker-cpu-shares 1024 \
    --docker-security-opt no-new-privileges \
    --docker-network-mode="runner-net"
  EOH
  sensitive true
  notifies :run, 'execute[restart_runner]', :immediate
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

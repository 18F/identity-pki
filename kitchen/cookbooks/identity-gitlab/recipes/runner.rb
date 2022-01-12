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

execute 'grab_gitlab_runner_repo' do
  command 'curl https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh | sudo bash'
  ignore_failure true
end

package 'gitlab-runner'

external_fqdn = "gitlab.#{node.chef_environment}.gitlab.identitysandbox.gov"
external_url = "https://#{external_fqdn}"
runner_name = node['hostname']
# Get token by following the 'Obtain a token' instructions on
# https://docs.gitlab.com/runner/register/#requirements
# Then put it in the secrets bucket for your env:
# aws s3 cp /tmp/gitlab_runner_token s3://<secretsbucket>/<env>/gitlab_runner_token
runner_token = ConfigLoader.load_config(node, "gitlab_runner_token", common: false).chomp


directory '/etc/systemd/system/gitlab-runner.service.d'

template '/etc/systemd/system/gitlab-runner.service.d/http-proxy.conf' do
	source 'http-proxy.conf.erb'
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
  http_proxy 'http://obproxy.login.gov.internal:3128'
  https_proxy 'http://obproxy.login.gov.internal:3128'
  no_proxy 'localhost,127.0.0.1,169.254.169.254,169.254.169.123,.login.gov.internal,ec2.us-west-2.amazonaws.com,kms.us-west-2.amazonaws.com,secretsmanager.us-west-2.amazonaws.com,ssm.us-west-2.amazonaws.com,ec2messages.us-west-2.amazonaws.com,lambda.us-west-2.amazonaws.com,ssmmessages.us-west-2.amazonaws.com,sns.us-west-2.amazonaws.com,sqs.us-west-2.amazonaws.com,events.us-west-2.amazonaws.com,metadata.google.internal,sts.us-west-2.amazonaws.com'
  icc false
  log_level 'debug'
  live_restore true
  userland_proxy false
end

aws_region = Chef::Recipe::AwsMetadata.get_aws_region
aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
no_proxy = 'localhost,127.0.0.1,169.254.169.254,169.254.169.123,.login.gov.internal,ec2.us-west-2.amazonaws.com,kms.us-west-2.amazonaws.com,secretsmanager.us-west-2.amazonaws.com,ssm.us-west-2.amazonaws.com,ec2messages.us-west-2.amazonaws.com,lambda.us-west-2.amazonaws.com,ssmmessages.us-west-2.amazonaws.com,sns.us-west-2.amazonaws.com,sqs.us-west-2.amazonaws.com,events.us-west-2.amazonaws.com,metadata.google.internal,sts.us-west-2.amazonaws.com'

# no_proxy seems to not actually work here.  Have to allow stuff in the proxy.  :-(
execute 'configure_gitlab_runner' do
	command "gitlab-runner register \
	  --non-interactive \
	  --name '#{runner_name}' \
	  --url '#{external_url}' \
	  --registration-token '#{runner_token}' \
	  --executor docker \
	  --env HTTP_PROXY=http://obproxy.login.gov.internal:3128 \
	  --env HTTPS_PROXY=http://obproxy.login.gov.internal:3128 \
	  --env http_proxy=http://obproxy.login.gov.internal:3128 \
	  --env https_proxy=http://obproxy.login.gov.internal:3128 \
	  --env NO_PROXY=#{no_proxy} \
	  --env no_proxy=#{no_proxy} \
	  --docker-image alpine:latest \
	  --tag-list 'docker,aws' \
	  --run-untagged=true \
	  --locked=false \
	  --cache-shared \
	  --cache-type s3 \
	  --cache-path '#{node.chef_environment}' \
	  --cache-s3-server-address s3.amazonaws.com \
	  --cache-s3-bucket-name 'login-gov-#{node.chef_environment}-gitlabcache-#{aws_account_id}-#{aws_region}' \
	  --cache-s3-bucket-location '#{aws_region}' \
	  --cache-s3-authentication_type 'iam' \
	  --access-level=not_protected
  "
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

template '/etc/audit/rules.d/30-login-gov-docker.rules' do
    source 'docker.rules.erb'
    owner 'root'
    group 'root'
    mode '0640'
    notifies :run, 'execute[restart_auditd]'
end

execute 'restart_auditd' do
	command "service auditd restart"
end

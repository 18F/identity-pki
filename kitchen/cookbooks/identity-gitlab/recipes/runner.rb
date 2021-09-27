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
runner_token = ConfigLoader.load_config(node, "gitlab_runner_token", common: false).chomp!

directory '/etc/gitlab'

template '/etc/gitlab/gitlab-runner-template.toml' do
    source 'gitlab-runner-template.toml.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables ({
        external_url: external_url,
		runner_name: runner_name
    })
    notifies :run, 'execute[configure_gitlab_runner]', :delayed
end

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

execute 'configure_gitlab_runner' do
  command "gitlab-runner register \
	  --non-interactive \
	  --config /etc/gitlab-runner/config.toml \
	  --template-config /etc/gitlab/gitlab-runner-template.toml \
	  --url #{external_url} \
	  --registration-token #{runner_token} \
	  --request-concurrency 4 \
	  --name #{runner_name} \
	  --executor shell
  "
  sensitive true
  action :nothing
  notifies :run, 'execute[restart_gitlab]', :immediate
end

execute 'restart_gitlab' do
	command 'systemctl restart gitlab-runner'
	action :nothing
end

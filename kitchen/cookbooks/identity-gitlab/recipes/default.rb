#
# Cookbook Name:: identity-gitlab
# Recipe:: default
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

package 'postfix'
package 'openssh-server'
package 'ca-certificates'
package 'tzdata'
package 'perl'

execute 'grab_gitlab_repo' do
  command 'curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | sudo bash'
  ignore_failure true
end

package 'gitlab-ee'

directory '/etc/gitlab/ssl'

remote_file "Copy cert" do 
  path "/etc/gitlab/ssl/#{node['fqdn']}.crt" 
  source "file:///etc/ssl/certs/server.crt"
  owner 'root'
  group 'root'
  mode 0644
end
remote_file "Copy key" do 
  path "/etc/gitlab/ssl/#{node['fqdn']}.key" 
  source "file:///etc/ssl/private/server.key"
  owner 'root'
  group 'root'
  mode 0600
end

template '/etc/gitlab/gitlab.rb' do
    source 'gitlab.rb.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
        external_url: "https://gitlab.#{node.chef_environment}.gitlab.identitysandbox.gov"
    })
    notifies :run, 'execute[reconfigure_gitlab]', :delayed
end

execute 'reconfigure_gitlab' do
  command '/usr/bin/gitlab-ctl reconfigure'
  action :nothing
end

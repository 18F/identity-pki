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

gitaly_ebs_volume = ConfigLoader.load_config(node, "gitaly_ebs_volume", common: false).chomp!
gitaly_device = "/dev/xvdi"

execute "mount_gitaly_volume" do
  command "aws ec2 attach-volume --device #{gitaly_device} --instance-id #{node['ec2']['instance_id']} --volume-id #{gitaly_ebs_volume} --region #{node['ec2']['region']}"
end

include_recipe 'filesystem'

filesystem 'gitaly' do
  fstype "ext4"
  device gitaly_device
  mount "/var/opt/gitlab/git-data"
  action [:create, :enable, :mount]
end

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

external_fqdn = "gitlab.#{node.chef_environment}.gitlab.identitysandbox.gov"
external_url = "https://#{external_fqdn}"

remote_file "Copy cert" do 
  path "/etc/gitlab/ssl/#{external_fqdn}.crt"
  source "file:///etc/ssl/certs/server.crt"
  owner 'root'
  group 'root'
  mode 0644
end

remote_file "Copy key" do 
  path "/etc/gitlab/ssl/#{external_fqdn}.key"
  source "file:///etc/ssl/private/server.key"
  owner 'root'
  group 'root'
  mode 0600
end

remote_file "rds_ca_bundle" do
  path "/etc/gitlab/ssl/rds_ca_bundle.pem"
  source "https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem"
  owner 'root'
  group 'root'
  mode 0644
end

db_password = ConfigLoader.load_config(node, "gitlab_db_password", common: false).chomp!
db_host = ConfigLoader.load_config(node, "gitlab_db_host", common: false).chomp!

template '/etc/gitlab/gitlab.rb' do
    source 'gitlab.rb.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables ({
        external_url: external_url,
        db_password: db_password,
        db_host: db_host
    })
    notifies :run, 'execute[reconfigure_gitlab]', :delayed
end

execute 'reconfigure_gitlab' do
  command '/usr/bin/gitlab-ctl reconfigure'
  action :nothing
end

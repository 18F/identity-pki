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

# This volume thing is ugly, but xvdg works, but xvdh does not create
# the /dev/xvdh symlink.  So we are just hardcoding the nvme devices
# it maps to directly.  WTF Ubuntu?
gitaly_ebs_volume = ConfigLoader.load_config(node, "gitaly_ebs_volume", common: false).chomp
gitaly_device = "/dev/xvdg"
gitaly_real_device = "/dev/nvme2n1"
gitlab_ebs_volume = ConfigLoader.load_config(node, "gitlab_ebs_volume", common: false).chomp
gitlab_device = "/dev/xvdh"
gitlab_real_device = "/dev/nvme3n1"

execute "mount_gitaly_volume" do
  command "aws ec2 attach-volume --device #{gitaly_device} --instance-id #{node['ec2']['instance_id']} --volume-id #{gitaly_ebs_volume} --region #{node['ec2']['region']}"
end

execute "mount_gitlab_volume" do
  command "aws ec2 attach-volume --device #{gitlab_device} --instance-id #{node['ec2']['instance_id']} --volume-id #{gitlab_ebs_volume} --region #{node['ec2']['region']}"
end

include_recipe 'filesystem'

filesystem 'gitaly' do
  fstype "ext4"
  device gitaly_real_device
  mount "/var/opt/gitlab/git-data"
  action [:create, :enable, :mount]
end

filesystem 'gitlab' do
  fstype "ext4"
  device gitlab_real_device
  mount "/etc/gitlab"
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

db_password = ConfigLoader.load_config(node, "gitlab_db_password", common: false).chomp
db_host = ConfigLoader.load_config(node, "gitlab_db_host", common: false).chomp
root_password = ConfigLoader.load_config(node, "gitlab_root_password", common: false).chomp
runner_token = ConfigLoader.load_config(node, "gitlab_runner_token", common: false).chomp
redis_host = ConfigLoader.load_config(node, "gitlab_redis_endpoint", common: false).chomp

ses_username = ConfigLoader.load_config(node, "ses_smtp_username", common: true).chomp
ses_password = ConfigLoader.load_config(node, "ses_smtp_password", common: true).chomp
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
smtp_address = "email-smtp.#{aws_region}.amazonaws.com"
email_from = "gitlab@#{external_fqdn}"

# Login.gov SAML parameters
saml_params = {
  saml_assertion_consumer_service_url: "#{external_url}/users/auth/saml/callback",
  saml_idp_cert_fingerprint: ConfigLoader.load_config(node, "saml_idp_cert_fingerprint", common: false).chomp,
  saml_idp_sso_target_url: 'https://idp.int.identitysandbox.gov/api/saml/auth2021',
  saml_issuer: "urn:gov:gsa:openidconnect.profiles:sp:sso:login_gov:gitlab_#{node.chef_environment}",
  saml_name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
  saml_certificate: ConfigLoader.load_config(node, "saml_certificate", common: false).chomp,
  saml_private_key: ConfigLoader.load_config(node, "saml_private_key", common: false).chomp,
}

template '/etc/gitlab/gitlab.rb' do
    source 'gitlab.rb.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables ({
        backup_s3_bucket: backup_s3_bucket,
        external_url: external_url,
        db_password: db_password,
        db_host: db_host,
        root_password: root_password,
        redis_host: redis_host,
        smtp_address: smtp_address,
        smtp_domain: external_fqdn,
        email_from: email_from,
        ses_username: ses_username,
        ses_password: ses_password,
        runner_token: runner_token,
    }.merge(saml_params))
    notifies :run, 'execute[reconfigure_gitlab]', :delayed
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  mode  '0600'
  notifies :run, 'execute[restart_sshd]', :delayed
end

execute 'reconfigure_gitlab' do
  command '/usr/bin/gitlab-ctl reconfigure'
  action :nothing
end

execute 'restart_sshd' do
  command 'service ssh reload'
  action :nothing
end

execute 'update_gitlab_settings' do
  command "gitlab-rails runner 'ApplicationSetting.last.update(signup_enabled: false)'"
  action :run
end

cron_d 'gitlab_backup_create' do
  predefined_value "@daily"
  command "gitlab-backup create"
end

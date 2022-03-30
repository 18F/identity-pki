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


aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
backup_s3_bucket = "login-gov-#{node.chef_environment}-gitlabbackups-#{aws_account_id}-#{aws_region}"
config_s3_bucket = "login-gov-#{node.chef_environment}-gitlabconfig-#{aws_account_id}-#{aws_region}"
db_host = ConfigLoader.load_config(node, "gitlab_db_host", common: false).chomp
db_password = ConfigLoader.load_config(node, "gitlab_db_password", common: false).chomp
if node.chef_environment == 'production' or node.chef_environment == 'bravo'
  external_fqdn = "#{node['login_dot_gov']['domain_name']}"  
else
  external_fqdn = "gitlab.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
end
gitaly_device = "/dev/xvdg"
gitaly_ebs_volume = ConfigLoader.load_config(node, "gitaly_ebs_volume", common: false).chomp
gitaly_real_device = "/dev/nvme2n1"
gitlab_device = "/dev/xvdh"
gitlab_ebs_volume = ConfigLoader.load_config(node, "gitlab_ebs_volume", common: false).chomp
gitlab_license = ConfigLoader.load_config(node, "login-gov.gitlab-license", common: true)
gitlab_qa_api_token = shell_out('openssl rand -base64 32 | sha256sum | head -c20').stdout
gitlab_real_device = "/dev/nvme3n1"
gitlab_root_api_token = shell_out('openssl rand -base64 32 | sha256sum | head -c20').stdout
runner_token = shell_out('openssl rand -base64 32 | sha256sum | head -c20').stdout
postgres_version = "13"
redis_host = ConfigLoader.load_config(node, "gitlab_redis_endpoint", common: false).chomp
root_password = ConfigLoader.load_config(node, "gitlab_root_password", common: false).chomp
ses_password = ConfigLoader.load_config(node, "ses_smtp_password", common: true).chomp
ses_username = ConfigLoader.load_config(node, "ses_smtp_username", common: true).chomp
smtp_address = "email-smtp.#{aws_region}.amazonaws.com"

#must come after external_fqdn
email_from = "gitlab@#{external_fqdn}"
external_url = "https://#{external_fqdn}"

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

execute "mount_gitaly_volume" do
  command "aws ec2 attach-volume --device #{gitaly_device} --instance-id #{node['ec2']['instance_id']} --volume-id #{gitaly_ebs_volume} --region #{aws_region}"
end

execute "mount_gitlab_volume" do
  command "aws ec2 attach-volume --device #{gitlab_device} --instance-id #{node['ec2']['instance_id']} --volume-id #{gitlab_ebs_volume} --region #{aws_region}"
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
package 'jq'

# https://packages.gitlab.com/gitlab/gitlab-ee/install#chef
# avoids running a shell script downloaded from a web server :)

packagecloud_repo "gitlab/gitlab-ee" do
  type "deb"
  base_url "https://packages.gitlab.com/"
end

directory '/etc/gitlab'

template '/etc/gitlab/gitlab.rb' do
    source 'gitlab.rb.erb'
    owner 'root'
    group 'root'
    mode '0600'
    variables ({
        aws_region: aws_region,
        aws_account_id: aws_account_id,
        backup_s3_bucket: backup_s3_bucket,
        postgres_version: postgres_version,
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

directory '/etc/gitlab/ssl'

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
  sensitive true
end

remote_file "rds_ca_bundle" do
  path "/etc/gitlab/ssl/rds_ca_bundle.pem"
  source "https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem"
  owner 'root'
  group 'root'
  mode 0644
end

file "gitlab_ee_license_file" do
  path "/etc/gitlab/login-gov.gitlab-license"
  content gitlab_license
  owner 'root'
  group 'root'
  mode 0644
  sensitive true
end

package 'gitlab-ee'

execute 'restore_ssh_keys' do
  command 'tar zxvf /etc/gitlab/etc_ssh.tar.gz'
  cwd '/etc'
  ignore_failure true
  notifies :run, 'execute[restart_sshd]', :delayed
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  mode  '0600'
  notifies :run, 'execute[restart_sshd]', :delayed
end

execute 'backup_ssh_keys' do
  command 'tar czf /etc/gitlab/etc_ssh.tar.gz ssh'
  cwd '/etc'
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
  command <<-EOF
    gitlab-rails runner 'ApplicationSetting.last.update(signup_enabled: false)'
  EOF
  action :run
end

file '/etc/gitlab/backup.sh' do
  content <<-EOF
    #!/bin/bash
    # backup github environment
    gitlab-backup create
    aws s3 cp /etc/gitlab/gitlab-secrets.json s3://#{backup_s3_bucket}/gitlab-secrets.json
    aws s3 cp /etc/gitlab/gitlab.rb s3://#{backup_s3_bucket}/gitlab.rb
    aws s3 cp /etc/ssh/ s3://#{backup_s3_bucket}/ssh --recursive --exclude "*" --include "ssh_host_*"
    aws s3 cp /etc/gitlab/ssl s3://#{backup_s3_bucket}/ssl --recursive
  EOF
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file '/etc/gitlab/restore.sh' do
  content <<-EOF
    #!/bin/bash
    # restore github environment, un-comment items to restore
    # aws s3 cp s3://#{backup_s3_bucket}/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json
    # aws s3 cp s3://#{backup_s3_bucket}/gitlab.rb /etc/gitlab/gitlab.rb
    # aws s3 cp s3://#{backup_s3_bucket}/ssh /etc/ssh/ --recursive --exclude "*" --include "ssh_host_*"
    # aws s3 cp s3://#{backup_s3_bucket}/ssl /etc/gitlab/ssl --recursive
    # aws s3 cp s3://#{backup_s3_bucket}/[date serial]-ee_gitlab_backup.tar /var/opt/gitlab/backups

    export GITLAB_ASSUME_YES=1
    gitlab-backup restore
  EOF
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

cron_d 'gitlab_backup_create' do
  action :create
  predefined_value "@daily"
  command '/etc/gitlab/backup.sh'
  notifies :create, 'file[/etc/gitlab/backup.sh]', :before
end

file '/etc/gitlab/gitlab_root_api_token' do
  content "#{gitlab_root_api_token}"
  mode '0600'
  owner 'root'
  group 'root'
end

execute 'copy_gitlab_runner_token_to_s3' do
  command "echo #{runner_token} | aws s3 cp - s3://#{config_s3_bucket}/gitlab_runner_token"
  sensitive true
  action :run
end

execute 'apply_runner_token' do
  command <<-EOF
    gitlab-rails runner "appSetting = Gitlab::CurrentSettings.current_application_settings; \
    appSetting.set_runners_registration_token('#{runner_token}'); \
    appSetting.save!"
  EOF
  sensitive true
  action :run
end

execute 'revoke_gitlab_tokens' do
  command <<-EOF
    gitlab-rails runner "User.find_by_username('root').personal_access_tokens.all.each(&:revoke!)"
  EOF
  action :run
end

execute 'save_gitlab_root_token' do
  command <<-EOF
    gitlab-rails runner "token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api], name: 'Automation Token'); \
    token.set_token('#{gitlab_root_api_token}'); token.save!"
  EOF
  action :run
end

execute 'clean_up_licenses' do
  command <<-EOF
    gitlab-rails runner 'License.all.each(&:destroy!); license_data = "#{gitlab_license}"; license = License.new(data: license_data); license.save'
  EOF
  action :run
  sensitive true
end

execute 'allow_users_to_create_groups' do
  command <<-EOF
    gitlab-rails runner "User.find_by_username('root').update!(can_create_group: true)"
  EOF
  action :run
end

execute 'add_ci_skeleton' do
  command <<-EOF
    if curl --silent --fail -o /dev/null "#{external_url}/"; then
      echo "URL exists: #{external_url}"
    else
      echo "URL does not exist: #{external_url}"
      exit
    fi

    GROUP_JSON=$(curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
      "#{external_url}/api/v4/groups" | jq '.[] | select(.name=="Login-Gov")')

    if [[ -z "$GROUP_JSON" ]]
    then
      echo "Creating LG Group"
      curl --silent --fail --request POST --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
        --header "Content-Type: application/json" \
        --data '{"name": "Login-Gov", "path": "lg", "description": "Login.gov Project Group"}' \
        "#{external_url}/api/v4/groups" | jq '.message'
      GROUP_JSON=$(curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
        "#{external_url}/api/v4/groups" | jq '.[] | select(.name=="Login-Gov")')
    else
      echo "LG Group Present"
    fi

    GROUP_NUMBER=$(echo $GROUP_JSON | jq 'select(.name=="Login-Gov") | .id')

    for repo in identity-devops identity-gitlab identity-devops-private gitlab
    do
      if [[ -z $(curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
      "#{external_url}/api/v4/projects?search=${repo}") ]]
      then
        echo "Creating ${repo} Project"
        curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
          "#{external_url}/api/v4/projects?name=${repo}&visibility=private&namespace_id=${GROUP_NUMBER}"
      else
        echo "${repo} Project Present"
      fi
    done

    USER_JSON=$(curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
      "#{external_url}/api/v4/users" | jq '.[] | select(.name=="gitlab-qa")')

    if [ -z "$USER_JSON" ]
    then
      echo "Creating gitlab-qa"
      curl --silent --fail --request POST --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
        --header "Content-Type: application/json" \
        --data '{"name": "gitlab-qa", "username": "gitlab-qa", "email": "test@#{external_fqdn}", "force_random_password": "true"}' \
        "#{external_url}/api/v4/users" | jq '.message'
      USER_JSON=$(curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
        "#{external_url}/api/v4/users" | jq '.[] | select(.name=="gitlab-qa")')
    else
      echo "LG gitlab-qa Present"
    fi

    PROJECT_RETURN=$(curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
      "#{external_url}/api/v4/groups/${GROUP_NUMBER}/projects?" | jq '.[] | select(.name=="identity-devops")')
    PROJECT_NUMBER=$(echo $PROJECT_RETURN | jq 'select(.name=="identity-devops") | .id')
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XDELETE \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables/GITLAB_API_TOKEN"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables" \
      --form "key=GITLAB_API_TOKEN" --form "value=#{gitlab_root_api_token}"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XDELETE \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables/AWS_ACCOUNT_ID"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables" \
       --form "key=AWS_ACCOUNT_ID" --form "value=#{aws_account_id}"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XDELETE \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables/GITLAB_QA_ACCOUNT"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables" \
      --form "key=GITLAB_QA_ACCOUNT" --form "value=gitlab-qa"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XDELETE \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables/EXTERNAL_FQDN"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables" \
      --form "key=EXTERNAL_FQDN" --form "value=#{external_fqdn}"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XDELETE \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables/AWS_REGION"
    curl --silent --fail --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{external_url}/api/v4/projects/${PROJECT_NUMBER}/variables" \
      --form "key=AWS_REGION" --form "value=#{aws_region}"
  EOF
  ignore_failure true
  sensitive true
  action :run
end


# this is to set up user/group syncing
remote_file "rds_ca_bundle" do
  path "/root/golang.tar.gz"
  source "https://go.dev/dl/go1.17.8.linux-amd64.tar.gz"
  owner 'root'
  group 'root'
  mode 0644
end

execute 'install_golang' do
  cwd '/usr/local'
  command <<-EOF
    tar zxpf /root/golang.tar.gz
  EOF
  action :run
end

file '/root/gitlabssh.sh' do
  content <<-EOF
    #!/bin/bash
    /usr/bin/ssh -i /etc/login.gov/keys/id_ecdsa.identity-devops.deploy
  EOF
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

execute 'build_usersync' do
  cwd '/etc/login.gov/repos/identity-devops/bin/users'
  command <<-EOF
    export PATH=$PATH:/usr/local/go/bin
    make build
  EOF
  action :run
end

template '/etc/hosts' do
    source 'hosts.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables ({
        external_fqdn: external_fqdn,
    })
end

cron_d 'run_usersync' do
  action :create
  predefined_value "@hourly"
  command "/etc/login.gov/repos/identity-devops/bin/users/sync.sh #{external_fqdn}"
end

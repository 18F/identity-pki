#
# Cookbook:: identity-gitlab
# Recipe:: default
#

# This volume thing is ugly, but xvdg works, but xvdh does not create
# the /dev/xvdh symlink.  So we are just hardcoding the nvme devices
# it maps to directly.  WTF Ubuntu?

# passwords are generated randomly
# root authentication tokens are revoked at the end of the chef run

aws_account_id = Chef::Recipe::AwsMetadata.get_aws_account_id
aws_region = Chef::Recipe::AwsMetadata.get_aws_region
backup_s3_bucket = "login-gov-#{node.chef_environment}-gitlabbackups-#{aws_account_id}-#{aws_region}"
config_s3_bucket = "login-gov-#{node.chef_environment}-gitlabconfig-#{aws_account_id}-#{aws_region}"
db_host = ConfigLoader.load_config(node, 'gitlab_db_host', common: false).chomp
db_instance_id = ConfigLoader.load_config(node, 'gitlab_instance_id', common: false).chomp
db_password = shell_out('openssl rand -base64 32 | sha256sum | head -c20').stdout
if node.chef_environment == 'production' || node.chef_environment == 'bravo'
  external_fqdn = "#{node['login_dot_gov']['domain_name']}"
else
  external_fqdn = "gitlab.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
end
gitaly_device = '/dev/xvdg'
gitaly_ebs_volume = ConfigLoader.load_config(node, 'gitaly_ebs_volume', common: false).chomp
gitaly_real_device = '/dev/nvme2n1'
gitlab_device = '/dev/xvdh'
gitlab_ebs_volume = ConfigLoader.load_config(node, 'gitlab_ebs_volume', common: false).chomp
gitlab_license = ConfigLoader.load_config(node, 'login-gov.gitlab-license', common: true)
gitlab_qa_account_name = 'gitlab-qa'
gitlab_qa_api_token = shell_out('openssl rand -base64 32 | sha256sum | head -c20').stdout
gitlab_qa_password = shell_out('openssl rand -base64 32 | sha256sum | head -c20').stdout
gitlab_real_device = '/dev/nvme3n1'
gitlab_root_api_token = shell_out('openssl rand -base64 32 | sha256sum | head -c20').stdout
local_url = 'https://localhost:443'
postgres_version = '13'
redis_host = ConfigLoader.load_config(node, 'gitlab_redis_endpoint', common: false).chomp
root_password = ConfigLoader.load_config(node, 'gitlab_root_password', common: false).chomp
runner_token = shell_out('openssl rand -base64 32 | sha256sum | head -c20').stdout
ses_password = ConfigLoader.load_config(node, 'ses_smtp_password', common: true).chomp
ses_username = ConfigLoader.load_config(node, 'ses_smtp_username', common: true).chomp
smtp_address = "email-smtp.#{aws_region}.amazonaws.com"
metric_namespace = ConfigLoader.load_config(node, 'gitlab_metric_namespace', common: false).chomp
user_sync_metric_name = ConfigLoader.load_config(node, 'gitlab_user_sync_metric_name', common: false).chomp

execute 'update_db_password' do
  command <<-EOF
    aws rds modify-db-instance --db-instance-identifier '#{db_instance_id}' --master-user-password '#{db_password}'
  EOF
  ignore_failure false
  action :run
  sensitive true
end

# must come after external_fqdn
email_from = "gitlab@#{external_fqdn}"
external_url = "https://#{external_fqdn}"

target_url = if node.chef_environment == 'production'
               'https://secure.login.gov/api/saml/auth2022'
             else
               'https://idp.int.identitysandbox.gov/api/saml/auth2021'
             end

# Login.gov SAML parameters
saml_params = {
  saml_assertion_consumer_service_url: "#{external_url}/users/auth/saml/callback",
  saml_idp_cert_fingerprint: ConfigLoader.load_config(node, 'saml_idp_cert_fingerprint', common: false).chomp,
  saml_idp_sso_target_url: target_url,
  saml_issuer: "urn:gov:gsa:openidconnect.profiles:sp:sso:login_gov:gitlab_#{node.chef_environment}",
  saml_name_identifier_format: 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent',
  saml_certificate: ConfigLoader.load_config(node, 'saml_certificate', common: false).chomp,
  saml_private_key: ConfigLoader.load_config(node, 'saml_private_key', common: false).chomp,
}

execute 'mount_gitaly_volume' do
  command "aws ec2 attach-volume --device #{gitaly_device} --instance-id #{node['ec2']['instance_id']} --volume-id #{gitaly_ebs_volume} --region #{aws_region}"
  retries 15
  retry_delay 60
end

execute 'mount_gitlab_volume' do
  command "aws ec2 attach-volume --device #{gitlab_device} --instance-id #{node['ec2']['instance_id']} --volume-id #{gitlab_ebs_volume} --region #{aws_region}"
  retries 15
  retry_delay 60
end

include_recipe 'filesystem'

filesystem 'gitaly' do
  fstype 'ext4'
  device gitaly_real_device
  mount '/var/opt/gitlab/git-data'
  action [:create, :enable, :mount]
end

filesystem 'gitlab' do
  fstype 'ext4'
  device gitlab_real_device
  mount '/etc/gitlab'
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

packagecloud_repo 'gitlab/gitlab-ee' do
  type 'deb'
  base_url 'https://packages.gitlab.com/'
end

directory '/etc/gitlab'

template '/etc/gitlab/gitlab.rb' do
  source 'gitlab.rb.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables({
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
  sensitive true
end

directory '/etc/gitlab/ssl'

remote_file 'Copy cert' do
  path "/etc/gitlab/ssl/#{external_fqdn}.crt"
  source 'file:///etc/ssl/certs/server.crt'
  owner 'root'
  group 'root'
  mode '644'
  sensitive true
end

remote_file 'Copy key' do
  path "/etc/gitlab/ssl/#{external_fqdn}.key"
  source 'file:///etc/ssl/private/server.key'
  owner 'root'
  group 'root'
  mode '600'
  sensitive true
end

remote_file 'rds_ca_bundle' do
  path '/etc/gitlab/ssl/rds_ca_bundle.pem'
  source 'https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem'
  owner 'root'
  group 'root'
  mode '644'
end

file 'gitlab_ee_license_file' do
  path '/etc/gitlab/login-gov.gitlab-license'
  content gitlab_license
  owner 'root'
  group 'root'
  mode '644'
  sensitive true
end

# https://packages.gitlab.com/gitlab/gitlab-ee
package 'gitlab-ee' do
  version '15.5.2-ee.0'
end

execute 'restore_ssh_keys' do
  command 'tar zxvf /etc/gitlab/etc_ssh.tar.gz'
  cwd '/etc'
  ignore_failure true
  notifies :run, 'execute[restart_sshd]', :delayed
  sensitive true
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  mode '0600'
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

file '/etc/gitlab/backup.sh' do
  content <<-EOF
#!/bin/bash
DATE="$(date +%Y%m%d%H%M)"
SNS_TOPIC_ARN="$(cat "/etc/login.gov/info/sns_topic_arn")"
AWS_REGION="#{aws_region}"

failure() {
  STATUS="FAILED"
  MESSAGE="gitlab backup $STATUS for #{node.chef_environment}:$DATE - $1"
  echo "$MESSAGE" | logger
  /usr/local/bin/aws sns publish \
    --region "$AWS_REGION" \
    --topic-arn "$SNS_TOPIC_ARN" \
    --message "$MESSAGE"
}

# backup github environment
gitlab-backup create || failure "gitlab-backup failed"
/usr/local/bin/aws s3 cp /etc/gitlab/gitlab-secrets.json s3://#{backup_s3_bucket}/$DATE/gitlab-secrets.json || failure "gitlab-secrets.json copy to s3 failed"
/usr/local/bin/aws s3 cp /etc/gitlab/gitlab.rb s3://#{backup_s3_bucket}/$DATE/gitlab.rb || failure "gitlab.rb copy to s3 failed"
/usr/local/bin/aws s3 cp /etc/ssh/ s3://#{backup_s3_bucket}/$DATE/ssh --recursive --exclude "*" --include "ssh_host_*" || failure "ssh copy to s3 failed"
/usr/local/bin/aws s3 cp /etc/gitlab/ssl s3://#{backup_s3_bucket}/$DATE/ssl --recursive || failure "ssl copy to s3 failed"

# make sure backups are not zero in size
find /var/opt/gitlab/backups -type f -size 0 | xargs -r false || failure "zero length backup file detected"

# Delete tempoary files
find /var/opt/gitlab/backups -type f -name '*.tar' -delete || failure "Some temporary backup files could not be deleted"

  EOF
  owner 'root'
  group 'root'
  mode '0755'
  action :create
end

file '/etc/gitlab/restore.sh' do
  content <<-EOF
#!/bin/bash

# define variables
# export DATE=202206071934
# export BACKUP_ARCHIVE_NAME=1655078426_2022_06_13_14.10.2-ee_gitlab_backup.tar
# export BACKUP_S3_BUCKET=#{backup_s3_bucket}

if [ -z "$DATE" ] && [ -z "$BACKUP_ARCHIVE_NAME" ] && [ -z "$REGION" ] ; then
  echo "please set the following environment variables DATE, BACKUP_ARCHIVE_NAME, and REGION"
  exit 1
fi

# restore github environment
aws s3 cp s3://$BACKUP_S3_BUCKET/$DATE/gitlab-secrets.json /etc/gitlab/gitlab-secrets.json
aws s3 cp s3://$BACKUP_S3_BUCKET/$DATE/gitlab.rb /etc/gitlab/gitlab.rb
aws s3 cp s3://$BACKUP_S3_BUCKET/$DATE/ssh /etc/ssh/ --recursive --exclude "*" --include "ssh_host_*"
aws s3 cp s3://$BACKUP_S3_BUCKET/$DATE/ssl /etc/gitlab/ssl --recursive
aws s3 cp s3://$BACKUP_S3_BUCKET/$BACKUP_ARCHIVE_NAME /var/opt/gitlab/backups
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
  predefined_value '@daily'
  command '/etc/gitlab/backup.sh'
  notifies :create, 'file[/etc/gitlab/backup.sh]', :before
  user 'root'
end

file '/etc/gitlab/gitlab_root_api_token' do
  content "#{gitlab_root_api_token}"
  mode '0600'
  owner 'root'
  group 'root'
end

execute 'copy_gitlab_runner_token_to_s3' do
  command "echo #{runner_token} | aws s3 cp - s3://#{config_s3_bucket}/gitlab_runner_token"
  action :run
  sensitive true
end

# Put these all together because it takes a TON of time to init rails.
# This may mask some failures of some of these commands, but I think that's OK?
execute 'gitlab_rails_commands' do
  command <<-EOF
    gitlab-rails runner " \
    begin; \
      puts 'update gitlab settings'; \
      ApplicationSetting.last.update(signup_enabled: false); \
    rescue; \
      puts 'XXX could not delete QA user'; \
    end; \
    \
    begin; \
      puts 'apply runner token'; \
      appSetting = Gitlab::CurrentSettings.current_application_settings; \
      appSetting.set_runners_registration_token('#{runner_token}'); \
      appSetting.save!; \
    rescue; \
      puts 'XXX could not apply runner token'; \
    end; \
    \
    begin; \
      puts 'revoke gitlab root tokens'; \
      User.find_by_username('root').personal_access_tokens.all.each(&:revoke!); \
    rescue; \
      puts 'XXX could not revoke root tokens'; \
    end; \
    \
    begin; \
      puts 'save gitlab root token'; \
      token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api], name: 'Automation Token'); \
      token.set_token('#{gitlab_root_api_token}'); token.save!; \
    rescue; \
      puts 'XXX could not save gitlab root token'; \
    end; \
    \
    begin; \
      puts 'clean up licenses'; \
      License.all.each(&:destroy!); license_data = '#{gitlab_license}'; license = License.new(data: license_data); license.save; \
    rescue; \
      puts 'XXX could not clean up licenses'; \
    end; \
    \
    begin; \
      puts 'allow root to create groups'; \
      User.find_by_username('root').update!(can_create_group: true); \
    rescue; \
      puts 'XXX could not allow root to create groups'; \
    end; \
    \
    begin ; \
      puts 'delete QA user'; \
      current_user = User.find_by(username: 'root'); qa_user = User.find_by_username('#{gitlab_qa_account_name}'); \
      DeleteUserWorker.perform_async(current_user.id, qa_user.id); \
    rescue; \
      puts 'XXX could not delete QA user'; \
    end; \
    \
    begin; \
      puts 'create QA user'; \
      qauser = User.new(username: '#{gitlab_qa_account_name}', email: 'qa@#{external_fqdn}', \
      name: 'QA User', password: '#{gitlab_qa_password}', password_confirmation: '#{gitlab_qa_password}', \
      can_create_group: 'true', admin: 'true'); qauser.skip_confirmation!; qauser.save!; \
    rescue; \
      puts 'XXX could not create QA user'; \
    end; \
    \
    begin; \
      puts 'create QA User token'; \
      token = User.find_by_username('#{gitlab_qa_account_name}').personal_access_tokens.create(scopes: [:api], name: 'Automation Token'); \
      token.set_token('#{gitlab_qa_api_token}'); token.save!; \
    rescue; \
      puts 'XXX could not create QA token'; \
    end; \
    \
    true"
  EOF
  action :run
  sensitive true
end


execute 'add_ci_skeleton' do
  command <<-EOF
    if curl --noproxy '*' --insecure --output /dev/null "#{local_url}/"; then
      echo "URL exists: #{local_url}"
    else
      echo "URL does not exist: #{local_url}"
      exit 1
    fi
    if (curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
      "#{local_url}/api/v4/groups" | jq '.[] | select(.path=="lg")')
    then
      echo "Creating LG Group"
      curl --request POST --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
        --header "Content-Type: application/json" \
        --data '{"name": "lg", "path": "lg", "description": "Login.gov Project Group"}' \
        "#{local_url}/api/v4/groups" | jq '.message'
    else
      echo "LG Group Present"
    fi
    GROUP_JSON=$(curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
      "#{local_url}/api/v4/groups" | jq '.[] | select(.path=="lg")')
    GROUP_NUMBER=$(echo $GROUP_JSON | jq 'select(.path=="lg") | .id')
    for repo in identity-devops identity-gitlab identity-devops-private gitlab
    do
      if (curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" "#{local_url}/api/v4/projects?search=$repo")
      then
        echo "Creating $repo Project"
        curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
          "#{local_url}/api/v4/projects?name=$repo&visibility=private&namespace_id=$GROUP_NUMBER"
      else
        echo "$repo Project Present"
      fi
    done
    PROJECT_JSON=$(curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" \
      "#{local_url}/api/v4/groups/$GROUP_NUMBER/projects?" | jq '.[] | select(.name=="identity-devops")')
    PROJECT_NUMBER=$(echo $PROJECT_JSON | jq 'select(.name=="identity-devops") | .id')
    for variable in GITLAB_QA_ACCOUNT GITLAB_QA_PASSWORD GITLAB_QA_API_TOKEN AWS_ACCOUNT_ID EXTERNAL_FQDN AWS_REGION
    do
      if (curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XGET \
        "#{local_url}/api/v4/projects/$PROJECT_NUMBER/variables/$variable"  | jq '.value')
      then
        echo "Deleting ENV Variable $variable"
        curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XDELETE \
          "#{local_url}/api/v4/projects/$PROJECT_NUMBER/variables/$variable"
      else
        echo "$variable Not Present"
      fi
    done
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{local_url}/api/v4/projects/$PROJECT_NUMBER/variables" \
      --form "key=GITLAB_QA_ACCOUNT" --form "value=#{gitlab_qa_account_name}" \
      --form "masked=true" --form "protected=true"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{local_url}/api/v4/projects/$PROJECT_NUMBER/variables" \
      --form "key=GITLAB_QA_PASSWORD" --form "value=#{gitlab_qa_password}" \
      --form "masked=true" --form "protected=true"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{local_url}/api/v4/projects/$PROJECT_NUMBER/variables" \
      --form "key=GITLAB_QA_API_TOKEN" --form "value=#{gitlab_qa_api_token}" \
      --form "masked=true" --form "protected=true"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{local_url}/api/v4/admin/ci/variables" \
       --form "key=AWS_ACCOUNT_ID" --form "value=#{aws_account_id}" \
      --form "masked=true" --form "protected=false"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{local_url}/api/v4/projects/$PROJECT_NUMBER/variables" \
      --form "key=EXTERNAL_FQDN" --form "value=#{external_fqdn}" \
      --form "masked=true" --form "protected=true"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{local_url}/api/v4/admin/ci/variables" \
      --form "key=AWS_REGION" --form "value=#{aws_region}" \
      --form "masked=true" --form "protected=false"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPUT \
      "#{local_url}/api/v4/application/settings?deactivate_dormant_users=true"
      curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPUT \
      "#{local_url}/api/v4/application/settings?user_deactivation_emails_enabled=false"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPUT \
      "#{local_url}/api/v4/application/settings?password_authentication_enabled_for_web=false"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPUT \
      "#{local_url}/api/v4/application/settings?admin_mode=true"
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPUT \
      "#{local_url}/api/v4/application/settings?plantuml_enabled=true&plantuml_url=#{external_url}/-/plantuml/"
    pipeline=$(curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XGET \
      "#{local_url}/api/v4/projects/$PROJECT_NUMBER/pipeline_schedules" | jq -r .[0])
    if [ "$pipeline" = "null" ]; then
      curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
        "#{local_url}/api/v4/projects/$PROJECT_NUMBER/pipeline_schedules" \
        --form description="Every 10 minutes" --form ref="main" --form cron="*/10 * * * *" --form cron_timezone="UTC" \
        --form active="true"
    fi
  EOF
  ignore_failure false
  action :run
  sensitive true
end

# this is to set up user/group syncing
remote_file 'golang' do
  path '/root/golang.tar.gz'
  source 'https://go.dev/dl/go1.19.linux-amd64.tar.gz'
  owner 'root'
  group 'root'
  mode '644'
  checksum '464b6b66591f6cf055bc5df90a9750bf5fbc9d038722bb84a9d56a2bea974be6'
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
    make
  EOF
  action :run
end

template '/etc/hosts' do
  source 'hosts.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
      external_fqdn: external_fqdn,
  })
end

cron_d 'run_usersync' do
  action :create
  predefined_value '@hourly'
  command "/etc/login.gov/repos/identity-devops/bin/users/sync.sh #{external_fqdn} #{metric_namespace} #{user_sync_metric_name} 2>&1 | logger --id=$$ -t users/sync.sh"
end

# set up logs for gitlab
template '/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.d/gitlabcw.json' do
  source 'gitlabcw.json.erb'
  owner 'root'
  group 'root'
  mode '0644'
  variables({
    environmentName: node.chef_environment,
  })
  notifies :restart, 'service[amazon-cloudwatch-agent]', :delayed
end

# Run PlantUML service
plantuml_version = 'v1.2020.10'
package 'tomcat8'
package 'openjdk-8-jdk'
package 'graphviz'

service 'tomcat8' do
  action :nothing
  supports({
    restart: true,
    status: true,
    start: true,
    stop: true,
  })
end

remote_file 'plantuml.war' do
  path '/var/lib/tomcat8/webapps/plantuml.war'
  source "https://github.com/plantuml/plantuml-server/releases/download/#{plantuml_version}/plantuml-#{plantuml_version}.war"
  owner 'tomcat8'
  group 'tomcat8'
  mode '600'
  notifies :restart, 'service[tomcat8]', :delayed
end

cookbook_file 'tomcat server.xml' do
  path '/etc/tomcat8/server.xml'
  source 'server.xml'
  owner 'root'
  group 'tomcat8'
  mode '640'
  notifies :restart, 'service[tomcat8]', :delayed
end

cookbook_file 'tomcat env vars' do
  path '/etc/default/tomcat8'
  source 'tomcat8'
  owner 'root'
  group 'root'
  mode '644'
  notifies :restart, 'service[tomcat8]', :delayed
end

# random gitlab maintenance tasks
# https://docs.gitlab.com/ee/administration/raketasks/maintenance.html

execute 'run_gitlab_db_reindex' do
  cwd '/opt/gitlab/embedded/service'
  command <<-EOF
    gitlab-rake gitlab:db:reindex
  EOF
  action :run
  ignore_failure true
end

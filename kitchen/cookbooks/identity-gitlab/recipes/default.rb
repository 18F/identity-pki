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
sns_topic_arn = ::File.read('/etc/login.gov/info/sns_topic_arn').chomp
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
pages_external_url = "https://pages.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}/"

target_url = if node.chef_environment == 'production' || node.chef_environment == 'gitstaging'
               'https://secure.login.gov/api/saml/auth2023'
             else
               'https://idp.int.identitysandbox.gov/api/saml/auth2023'
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

# Extending the /var filesystem for bigger temporary backup generation
# backups are in /var/opt/gitlab/backups
execute 'pvresize_nvme1n1' do
  command 'pvresize /dev/nvme1n1'
  action :run
  user 'root'
  group 'root'
end

# Map 100% of the free space to the /var filesystem
execute 'lvextend_securefolders-variables' do
  command 'lvextend -l +100%FREE /dev/mapper/securefolders-variables'
  action :run
  user 'root'
  group 'root'
end

# Resize the filesystem to use the new space
execute 'resize2fs_securefolders-variables' do
  command 'resize2fs /dev/mapper/securefolders-variables'
  action :run
  user 'root'
  group 'root'
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
      external_fqdn: external_fqdn,
      pages_external_url: pages_external_url,
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
  source 'https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem'
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

# make sure that the uid/gid is static, and can access the ssh keys
group 'git' do
  gid 994
  system true
end

user 'git' do
  comment 'Gitlab user'
  uid 993
  gid 'git'
  home '/var/opt/gitlab'
  shell '/bin/sh'
  system true
end

group 'github' do
  append true
  members 'git'
end

execute 'chgrp git /etc/login.gov/keys/id_ecdsa.identity-servers'

package 'gitlab-ee' do
  version node['identity_gitlab']['gitlab_version']
end

# Loosen permissions on gitaly data directory on 20.04
if node['platform_version'].to_f == 20.04
  directory '/var/opt/gitlab/git-data' do
    owner 'git'
    group 'git'
    mode '0750'
    recursive true
    action :create
  end
end

# Restore SSH Keys from S3 Bucket
execute 'restore_ssh_keys_from_s3' do
  command <<-EOF
    aws s3 cp s3://#{backup_s3_bucket}/ssh/etc_ssh.tar.gz /tmp/etc_ssh.tar.gz
    tar xzf /tmp/etc_ssh.tar.gz -C /etc
  EOF
  notifies :run, 'execute[restart_sshd]', :delayed
  ignore_failure true
end

template '/etc/ssh/sshd_config' do
  source 'sshd_config.erb'
  mode '0600'
  notifies :run, 'execute[restart_sshd]', :delayed
end

# Backup SSH Keys to S3 Bucket
execute 'backup_ssh_keys_to_s3' do
  command <<-EOF
    tar czf /tmp/etc_ssh.tar.gz -C /etc ssh
    aws s3 cp /tmp/etc_ssh.tar.gz s3://#{backup_s3_bucket}/ssh/etc_ssh.tar.gz
  EOF
  cwd '/etc'
  ignore_failure false
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
DATE=$(date +%Y%m%d%H%M)
BACKUP_FILENAME=${DATE}_ee_gitlab_#{node['identity_gitlab']['gitlab_version']}
CONFIG_FILENAME=${DATE}_config_backup.tar.gz
SNS_TOPIC_ARN=$(cat "/etc/login.gov/info/sns_topic_arn")
AWS_REGION=#{aws_region}
ENVIRONMENT=#{node.chef_environment}
SLACK_HANDLE=\\<\\!subteam\\^SUY1QMZE3\\>
BACKUP_S3_BUCKET=#{backup_s3_bucket}

failure() {
  STATUS="FAILED"

  if [ ${ENVIRONMENT} = "production" ]; then
    echo "gitlab backup ${STATUS} for ${ENVIRONMENT}:${DATE} - $1 ${SLACK_HANDLE} https://github.com/18F/identity-devops/wiki/Disaster-Recovery:-Gitlab-Backup-and-Restore" > .message
  else
    echo "gitlab backup ${STATUS} for ${ENVIRONMENT}:${DATE} - $1" > .message
  fi

  cat .message | logger
  /usr/local/bin/aws sns publish \
    --region ${AWS_REGION} \
    --topic-arn ${SNS_TOPIC_ARN} \
    --message file://.message
}

# backup github
gitlab-backup create BACKUP=${BACKUP_FILENAME} || failure "gitlab-backup failed"

# backup config
tar -czvf ${CONFIG_FILENAME} /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab.rb /etc/gitlab/gitlab_root_api_token /etc/gitlab/login-gov.gitlab-license /etc/ssh/ /etc/gitlab/ssl
/usr/local/bin/aws s3 cp ${CONFIG_FILENAME} s3://${BACKUP_S3_BUCKET}/${CONFIG_FILENAME} || failure "gitlab-secrets.json copy to s3 failed"

backup_size=$(/usr/local/bin/aws s3api head-object --bucket ${BACKUP_S3_BUCKET} --key "${BACKUP_FILENAME}_gitlab_backup.tar" --query "ContentLength")
config_size=$(/usr/local/bin/aws s3api head-object --bucket ${BACKUP_S3_BUCKET} --key ${CONFIG_FILENAME} --query "ContentLength")

if [ -z $backup_size ] || [ -z $config_size ]; then
  failure "one or more variables are undefined"
  exit 1
fi

if [ $backup_size -eq 0 ] || [ $config_size -eq 0 ]; then
  failure "one or more file sizes are zero"
  exit 1
fi

sleep 30 # Allow s3 time to report correct file information

config_hash=($(md5sum ${CONFIG_FILENAME}))
s3_config_hash=$(/usr/local/bin/aws s3api head-object --bucket #{backup_s3_bucket} --key ${CONFIG_FILENAME} --query ETag --output text | tr -d '"')

if [[ $config_hash != $s3_config_hash ]]; then
  failure "config sha ${config_hash} does not match for s3 config sha ${s3_config_hash}"
  exit 1
fi

# Delete tempoary files
find /var/opt/gitlab/backups -type f -name '*.tar' -delete || failure "Some temporary backup files could not be deleted"
find /etc/gitlab -type f -name '*.tar.gz' -delete || failure "Some temporary backup files could not be deleted"

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
# export BACKUP_ARCHIVE_NAME=202212202123_ee_gitlab_15.6.1-ee.0_gitlab_backup.tar
# export CONFIG_ARCHIVE_NAME=202212202123_config_backup.tar.gz
# export BACKUP_S3_BUCKET=#{backup_s3_bucket}

if [ -z "${BACKUP_ARCHIVE_NAME}" ] && [ -z "${CONFIG_ARCHIVE_NAME}" ] && [ -z "$REGION" ] ; then
  echo "please set the following environment variables BACKUP_ARCHIVE_NAME, CONFIG_ARCHIVE_NAME and REGION"
  exit 1
fi

# copy down github backup files
aws s3 cp s3://$BACKUP_S3_BUCKET/${BACKUP_ARCHIVE_NAME} /var/opt/gitlab/backups
aws s3 cp s3://$BACKUP_S3_BUCKET/${CONFIG_ARCHIVE_NAME} /etc/gitlab/

# The Config Archive will need to be restored by hand and should contain the following directories and files
# /etc/gitlab/gitlab-secrets.json /etc/gitlab/gitlab.rb /etc/gitlab/gitlab_root_api_token /etc/gitlab/login-gov.gitlab-license /etc/ssh/ /etc/gitlab/ssl

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

file '/etc/gitlab/repo_mirror_alarm.sh' do
  content <<-EOF
#!/bin/bash

debug=0
gitlab_token=$(cat /etc/gitlab/gitlab_root_api_token)
sns_topic_arn=$(cat /etc/login.gov/info/sns_topic_arn)
aws_region=#{aws_region}
external_url=#{external_url}
environment=#{node.chef_environment}
slack_handle=\\<\\!subteam\\^SUY1QMZE3\\>

failure() {
  echo $1 > .message

  cat .message | logger
  /usr/local/bin/aws sns publish \
    --region ${aws_region} \
    --topic-arn ${sns_topic_arn} \
    --message file://.message
}

project_json=$(curl -s --noproxy '*' --insecure --header "PRIVATE-TOKEN: ${gitlab_token}" \
  "${external_url}/api/v4/projects?" | jq '.[] | select(.name=="identity-devops")')
rv="$?"
if [[ $rv -ne 0 || ! $project_json ]]; then
    echo "failed to get project_json" 1>&2
    exit 1
fi
if [[ $debug -ne 0 || ! $debug ]]; then
    echo "project_json set to $project_json" 1>&2
fi

project_number=$(echo $project_json | jq '.id')
rv="$?"
if [[ $rv -ne 0 || ! $project_number ]]; then
    echo "failed to get project_number" 1>&2
    exit 1
fi
if [[ $debug -ne 0 || ! $debug ]]; then
    echo "project_number set to $project_number" 1>&2
fi

mirror_update_time=$(curl -s --noproxy '*' --insecure --header "PRIVATE-TOKEN: ${gitlab_token}" \
"${external_url}/api/v4/projects/${project_number}/mirror/pull" | jq -r '.last_successful_update_at')
rv="$?"
if [[ $rv -ne 0 || ! $mirror_update_time ]]; then
    echo "failed to get mirror_update_time" 1>&2
    exit 1
fi
if [[ $debug -ne 0 || ! $debug ]]; then
    echo "mirror_update_time set to $mirror_update_time" 1>&2
fi

mirror_date_serial=$(date -d $mirror_update_time "+%s")
rv="$?"
if [[ $rv -ne 0 || ! $mirror_date_serial ]]; then
    echo "failed to get mirror_date_serial" 1>&2
    exit 1
fi
if [[ $debug -ne 0 || ! $debug ]]; then
    echo "mirror_date_serial set to $mirror_date_serial" 1>&2
fi

current_date_serial=$(date "+%s")
rv="$?"
if [[ $rv -ne 0 || ! $current_date_serial ]]; then
    echo "failed to get current_date_serial" 1>&2
    exit 1
fi
if [[ $debug -ne 0 || ! $debug ]]; then
    echo "current_date_serial set to $current_date_serial" 1>&2
fi

delta=$(( $current_date_serial - $mirror_date_serial ))
rv="$?"
if [[ $rv -ne 0 || ! $delta ]]; then
    echo "failed to get delta" 1>&2
    exit 1
fi
if [[ $debug -ne 0 || ! $debug ]]; then
    echo "delta set to $delta" 1>&2
fi

if [ "$delta" -ge 600 ]; then
      failure "warning:  Identity-devops in Gitlab ${environment} is out of date by ${delta} seconds ${slack_handle}"
    else
      echo "Identity-devops in ${environment} has synced recently"
fi
EOF
  owner 'root'
  group 'root'
  mode '0755'
  action :create
  only_if { node.chef_environment == 'production' }
end

cron_d 'identity_devops_mirror_check' do
  action :create
  predefined_value '@hourly'
  command '/etc/gitlab/repo_mirror_alarm.sh'
  notifies :create, 'file[/etc/gitlab/backup.sh]', :before
  user 'root'
  only_if { node.chef_environment == 'production' }
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
      token = User.find_by_username('root').personal_access_tokens.create(scopes: [:api, :admin_mode], name: 'Automation Token'); \
      token.set_token('#{gitlab_root_api_token}'); \
      token.expires_at = 90.days.from_now; \
      token.save!; \
    rescue; \
      puts 'XXX could not save gitlab root token'; \
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
    curl --noproxy '*' --insecure --header "PRIVATE-TOKEN: #{gitlab_root_api_token}" -XPOST \
      "#{local_url}/api/v4/admin/ci/variables" \
      --form "key=SNS_ALERT_TOPIC_ARN" --form "value=#{sns_topic_arn}" \
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
  only_if { node['identity_gitlab']['user_sync_cron_enable'] }
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
# Tomcat8 is able to apt install in 18.04
if node['platform_version'].to_f == 18.04
  tomcat_version = '8'
  tomcat_user = 'tomcat8'
  tomcat_group = 'tomcat8'
# Tomcat8 is not a package in 20.04, need to migrate to tomcat9
elsif node['platform_version'].to_f == 20.04
  tomcat_version = '9'
  tomcat_user = 'tomcat'
  tomcat_group = 'tomcat'
  # Tomcat9 package install fails if tomcat user:group isn't created
  group 'tomcat' do
    action :create
  end

  user 'tomcat' do
    comment 'Tomcat user'
    gid 'tomcat'
    shell '/bin/false'
    home '/opt/tomcat'
    action :create
  end
end
package "tomcat#{tomcat_version}"
package 'openjdk-8-jdk'
package 'graphviz'

service "tomcat#{tomcat_version}" do
  action :nothing
  supports({
    restart: true,
    status: true,
    start: true,
    stop: true,
  })
end

remote_file 'plantuml.war' do
  path "/var/lib/tomcat#{tomcat_version}/webapps/plantuml.war"
  source "https://github.com/plantuml/plantuml-server/releases/download/#{plantuml_version}/plantuml-#{plantuml_version}.war"
  owner tomcat_user
  group tomcat_group
  mode '600'
  notifies :restart, "service[tomcat#{tomcat_version}]", :delayed
end

cookbook_file 'tomcat server.xml' do
  path "/etc/tomcat#{tomcat_version}/server.xml"
  source 'server.xml'
  owner 'root'
  group tomcat_group
  mode '640'
  notifies :restart, "service[tomcat#{tomcat_version}]", :delayed
end

if node['platform_version'].to_f == 18.04
  cookbook_file 'tomcat env vars' do
    path "/etc/default/tomcat#{tomcat_version}"
    source "tomcat#{tomcat_version}"
    owner 'root'
    group 'root'
    mode '644'
    notifies :restart, "service[tomcat#{tomcat_version}]", :delayed
  end
elsif node['platform_version'].to_f == 20.04
  cookbook_file 'tomcat systemd unit' do
    path "/usr/lib/systemd/system/tomcat#{tomcat_version}.service"
    source "tomcat#{tomcat_version}.service"
    owner 'root'
    group 'root'
    mode '644'
    notifies :restart, "service[tomcat#{tomcat_version}]", :delayed
  end

  execute 'reload_systemctl_units' do
    command 'systemctl daemon-reload'
    action :run
    notifies :restart, "service[tomcat#{tomcat_version}]", :delayed
  end
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

# send metrics to cloudwatch
template '/etc/gitlab/gitlabmetrics.sh' do
  source 'gitlabmetrics.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
  variables({
      aws_region: aws_region,
      aws_account_id: aws_account_id,
  })
end

cron_d 'gitlab_metrics' do
  action :create
  minute '*/5'
  command '/etc/gitlab/gitlabmetrics.sh'
  user 'root'
end

# set all resources in identity-devops to be oldest_first to ensure ordered deploys
template '/etc/gitlab/oldest_first_resources.sh' do
  source 'oldest_first_resources.sh.erb'
  owner 'root'
  group 'root'
  mode '0700'
end

execute 'oldest_first' do
  command '/etc/gitlab/oldest_first_resources.sh'
  action :run
end

# enable the kubernetes access server
directory '/var/opt/gitlab/gitlab-kas' do
  recursive true
end

directory '/var/opt/gitlab/gitlab-kas/sockets' do
  owner 'git'
end

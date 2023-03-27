pivcac_node = node.fetch('pivcac')
deploy_hook = '/usr/local/bin/push_letsencrypt_certs.sh'

# push_letsencrypt_certs is called by certbot if and only if there are new certs
# in place that need to be shared via S3.
template deploy_hook do
  source 'push_letsencrypt_certs.sh.erb'
  mode '0755'
  variables({
    letsencrypt_bundle: pivcac_node.fetch('temporary_bundle_path'),
    letsencrypt_parent_dir: File.dirname(pivcac_node.fetch('letsencrypt_path')),
    letsencrypt_base_dir: File.basename(pivcac_node.fetch('letsencrypt_path')),
    letsencrypt_bucket: pivcac_node.fetch('bucket')
  })
end

letsencrypt_bundle_from_s3 = AwsS3.download(pivcac_node.fetch('bucket'), pivcac_node.fetch('letsencrypt_bundle'))

# first and always sync from s3
temporary_bundle_path = pivcac_node.fetch('temporary_bundle_path')
file temporary_bundle_path do
  content letsencrypt_bundle_from_s3
end

# `certbot renew` uses this file to configure renewals.
renewal_config = "#{pivcac_node.fetch('letsencrypt_path')}/renewal/#{pivcac_node.fetch('domain')}.conf"

# extract what we got from s3 unless it's an empty file
execute "tar zxvf #{pivcac_node.fetch('temporary_bundle_path')}" do
  only_if {::File.exists?(pivcac_node.fetch('temporary_bundle_path'))}
  # If the file was not in S3, this will be an empty file.
  not_if {::File.zero?(pivcac_node.fetch('temporary_bundle_path'))}
  # execute tar in the parent of letsencrypt_path (i.e. probably /etc)
  cwd File.dirname(pivcac_node.fetch('letsencrypt_path'))
  creates renewal_config
  notifies :restart, "service[passenger]"
end

# I wanted to do this all in attributes but it wasn't handling the $ENV.json
# overrides correctly. v02 servers are necessary for wildcard certs.
if pivcac_node.fetch('letsencrypt_use_staging')
  letsencrypt_server = 'https://acme-staging-v02.api.letsencrypt.org/directory'
else
  letsencrypt_server = 'https://acme-v02.api.letsencrypt.org/directory'
end

# if we have no valid content from S3, which should only happen when we turn
# up this service in a new environment, we do a full certbot run, then use
# deploy_hook to push the new certs to S3.
execute "run certbot for the first time" do
  not_if {::File.exists?(renewal_config)}
  only_if {::File.zero?(pivcac_node.fetch('temporary_bundle_path'))}
  
  command "/snap/bin/certbot certonly --agree-tos -n --dns-route53 -d #{pivcac_node.fetch('wildcard')} --email #{pivcac_node.fetch('letsencrypt_email')} --server #{letsencrypt_server} --deploy-hook #{deploy_hook} --preferred-chain '#{pivcac_node.fetch('letsencrypt_preferred')}'  --key-type #{pivcac_node.fetch('letsencrypt_key_type')} #{pivcac_node.fetch('letsencrypt_key_type') == 'rsa' ? '--rsa-key-size 2048' : ''} "
  creates renewal_config
end

# Run this whenever we can. Most times it will do nothing. If it performs a
# renewal, it will call deploy_hook and push the certs back to S3.
execute 'certbot renew' do
  only_if { ::File.exists?(renewal_config) }
  command "/snap/bin/certbot renew -n --deploy-hook #{deploy_hook}  --preferred-chain '#{pivcac_node.fetch('letsencrypt_preferred')}' --key-type #{pivcac_node.fetch('letsencrypt_key_type')} #{pivcac_node.fetch('letsencrypt_key_type') == 'rsa' ? '--rsa-key-size 2048' : ''}"
end

# update_letsencrypt_certs is called by cron and runs this recipe.
update_script = '/usr/local/bin/update_letsencrypt_certs'
template update_script do
  source 'update_letsencrypt_certs.erb'
  mode '0755'
  variables({
    chef_zero_client_configuration: pivcac_node.fetch('chef_zero_client_configuration')
  })
end
update_script_with_lock = "flock -n /tmp/update_letsencrypt_certs.lock "\
                          "-c #{update_script}"


# Run this once a day on each server - there is a random sleep built into the
# script.
cron_d 'update_letsencrypt_certs' do
  predefined_value "@daily"
  # if random_delay is ever implemented properly we can lose the "sleep"
  command update_script_with_lock
end


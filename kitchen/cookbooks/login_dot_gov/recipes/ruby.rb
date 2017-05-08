encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

template '/home/ubuntu/.bash_profile' do
  owner node['login_dot_gov']['system_user']
  mode '0644'
  sensitive true
  variables({
    new_relic_license_key: encrypted_config['newrelic_license_key'],
    idp_slo_url: "https://idp.#{node.chef_environment}.login.gov/api/saml/logout",
    idp_sp_url: "https://#{encrypted_config['basic_auth_user_name']}:#{encrypted_config['basic_auth_password']}@idp.#{node.chef_environment}.login.gov/api/service_provider",
    idp_sso_url: "https://idp.#{node.chef_environment}.login.gov/api/saml/auth",
    secret_key_base_dashboard: encrypted_config['secret_key_base_dashboard'],
    secret_key_base: encrypted_config['secret_key_base_rails'],
    smtp_domain:  node['set_fqdn'],
    smtp_password: encrypted_config['smtp_settings']['password'],
    smtp_user: encrypted_config['smtp_settings']['user_name'],
    sp_name: encrypted_config['basic_auth_user_name'],
    sp_pass: encrypted_config['basic_auth_password']
  })
  subscribes :run, 'execute[ruby-build install]', :delayed
end

# add to users path
template '/etc/environment' do
  source 'environment.erb'
  sensitive true
  variables({
    dashboard_log: "/srv/dashboard/log/shared/production.log",
    dashboard_secret_key_base: encrypted_config['secret_key_base_dashboard'],
    newrelic_license_key: encrypted_config['newrelic_license_key'],
    ruby_version: node['login_dot_gov']['ruby_version'],
    saml_env: node.chef_environment,
    smtp_address: encrypted_config['smtp_settings']['address'],
    smtp_domain: node['set_fqdn'],
    smtp_password: encrypted_config['smtp_settings']['password'],
    smtp_username: encrypted_config['smtp_settings']['user_name'],
    sp_name: encrypted_config['basic_auth_user_name'],
    sp_pass: encrypted_config['basic_auth_password']
  })
end

# install dependencies
# TODO: JJG convert to platform agnostic way of installing packages to avoid case statement(s)
execute "apt-get update"

case
when platform_family?('rhel')
  ['cyrus-sasl-devel',
   'libtool-ltdl-devel',
   'postgresql-devel',
   'ruby-devel',
   'nodejs',
   'npm'].each { |pkg| package pkg }
when platform_family?('debian')
  ['libpq-dev',
   'libsasl2-dev',
   'ruby-dev',
   'nodejs',
   'npm'].each { |pkg| package pkg }
end

#execute 'source /etc/environment'

# install ruby
ruby_runtime node['login_dot_gov']['ruby_version'] do
  provider :ruby_build
end

execute "chown -R #{node['login_dot_gov']['system_user']}:adm /opt/ruby_build"

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

template '/home/ubuntu/.bash_profile' do
  owner node['login_dot_gov']['system_user']
  mode '0644'
  sensitive true
  variables({
    idp_sp_url: "https://idp.#{node.chef_environment}.login.gov/api/service_provider",
    new_relic_license_key: encrypted_config['newrelic_license_key'],
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
  variables({
    ruby_version: node['login_dot_gov']['ruby_version']
  })
end

# install dependencies
# TODO: JJG convert to platform agnostic way of installing packages to avoid case statement(s)
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

directory '/home/ubuntu/.postgresql' do
  group node['login_dot_gov']['system_user']
  owner node['login_dot_gov']['system_user']
  recursive true
end

remote_file '/home/ubuntu/.postgresql/root.crt' do
  group node['login_dot_gov']['system_user']
  mode 0600
  owner node['login_dot_gov']['system_user']
  sensitive true # nothing sensitive but using to remove unnecessary output
  source 'https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem'
  action :create
end

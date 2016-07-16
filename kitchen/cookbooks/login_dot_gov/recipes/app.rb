# setup idp app

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

execute 'update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100' do
  not_if { ::File.exists? '/usr/bin/node' }
end

# TODO: JJG consider migrating to chef deploy resource to stay in line with capistrano style:
# https://docs.chef.io/resource_deploy.html
application '/srv/idp' do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  ruby node['login_dot_gov']['ruby_version']

  git do
    action :export
    repository 'https://github.com/18F/identity-idp.git'
    user node['login_dot_gov']['system_user']
  end

  template "/srv/idp/config/application.yml" do
    action :create
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
    variables({
      allow_third_party_auth: node['login_dot_gov']['allow_third_party_auth'],
      domain_name: node['login_dot_gov']['domain_name'],
      google_analytics_key: Chef::EncryptedDataBagItem.load('config', 'app')['production']['google_analytics_key'],
      idp_sso_target_url: node['login_dot_gov']['idp_sso_target_url'],
      logins_per_ip_limit: node['login_dot_gov']['logins_per_ip_limit'],
      logins_per_ip_period: node['login_dot_gov']['logins_per_ip_period'],
      mailer_domain_name: node['login_dot_gov']['mailer_domain_name'],
      newrelic_license_key: Chef::EncryptedDataBagItem.load('config', 'app')['production']['newrelic_license_key'],
      proofing_vendors: node['login_dot_gov']['proofing_vendors'],
      pt_mode: node['login_dot_gov']['pt_mode'],
      requests_per_ip_limit: node['login_dot_gov']['requests_per_ip_limit'],
      requests_per_ip_period: node['login_dot_gov']['requests_per_ip_period'],
      saml_passphrase: Chef::EncryptedDataBagItem.load('config', 'app')['production']['saml_passphrase'],
      secret_key_base: Chef::EncryptedDataBagItem.load('config', 'app')['production']['secret_key_base'],
      smtp_settings: Chef::EncryptedDataBagItem.load('config', 'app')['production']['smtp_settings'],
      support_url: node['login_dot_gov']['support_url'],
      twilio_accounts: Chef::EncryptedDataBagItem.load('config', 'app')['production']['twilio_accounts']
    })
  end

  file "/srv/idp/certs/saml.crt" do
    action :create
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  file "/srv/idp/keys/saml.key.enc" do
    action :create
    content Chef::EncryptedDataBagItem.load('config', 'keys')['saml.key.enc']
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  bundle_install do
    deployment true
    without %w{development test}
  end

  # install browserify
  execute 'npm install' do
    creates 'node_modules'
    cwd '/srv/idp'
  end

  rails do
    # for some reason you can't set the database name when using ruby block format. Perhaps it has
    # something to do with having the same name as the resource to which the block belongs.
    database({
      adapter: 'postgresql',
      database: Chef::EncryptedDataBagItem.load('config', 'app')['production']['db_database'],
      username: Chef::EncryptedDataBagItem.load('config', 'app')['production']['db_username'],
      host: Chef::EncryptedDataBagItem.load('config', 'app')['production']['db_host'],
      password: Chef::EncryptedDataBagItem.load('config', 'app')['production']['db_password']
    })
    rails_env node['login_dot_gov']['rails_env']
    secret_token node['login_dot_gov']['secret_token']
    migrate false
  end
  
  notifies :restart, "service[passenger]"
end

# add nginx conf for app server
template "/opt/nginx/conf/sites.d/idp.login.gov.conf" do
  source 'nginx_server.conf.erb'
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
end

directory '/srv/idp' do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
end

login_dot_gov_lets_encrypt 'idp'

include_recipe "passenger::daemon"

execute "mount -o remount,nosuid,nodev /tmp"

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

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

execute 'update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100' do
  not_if { ::File.exists? '/usr/bin/node' }
end

%w{certs keys config}.each do |dir|
  directory "/srv/idp/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['system_user']
    recursive true
  end
end

release_path = '/srv/idp/releases/chef'

directory release_path do
  recursive true
end

# TODO: JJG consider migrating to chef deploy resource to stay in line with capistrano style:
# https://docs.chef.io/resource_deploy.html
application release_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  ruby node['login_dot_gov']['ruby_version']

  git do
    repository 'https://github.com/18F/identity-idp.git'
    user node['login_dot_gov']['system_user']
  end

  template "#{release_path}/config/application.yml" do
    action :create
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
    variables({
      allow_third_party_auth: node['login_dot_gov']['allow_third_party_auth'],
      domain_name: node['login_dot_gov']['domain_name'],
      google_analytics_key: encrypted_config['google_analytics_key'],
      idp_sso_target_url: node['login_dot_gov']['domain_name'],
      logins_per_ip_limit: node['login_dot_gov']['logins_per_ip_limit'],
      logins_per_ip_period: node['login_dot_gov']['logins_per_ip_period'],
      mailer_domain_name: node['login_dot_gov']['domain_name'],
      newrelic_license_key: encrypted_config['newrelic_license_key'],
      otp_delivery_blocklist_bantime: node['login_dot_gov']['otp_delivery_blocklist_bantime'],
      otp_delivery_blocklist_findtime: node['login_dot_gov']['otp_delivery_blocklist_findtime'],
      otp_delivery_blocklist_maxretry: node['login_dot_gov']['otp_delivery_blocklist_maxretry'],
      proofing_vendors: node['login_dot_gov']['proofing_vendors'],
      pt_mode: node['login_dot_gov']['pt_mode'],
      redis_url: encrypted_config['redis_url'],
      requests_per_ip_limit: node['login_dot_gov']['requests_per_ip_limit'],
      requests_per_ip_period: node['login_dot_gov']['requests_per_ip_period'],
      saml_passphrase: encrypted_config['saml_passphrase'],
      secret_key_base: encrypted_config['secret_key_base'],
      smtp_settings: encrypted_config['smtp_settings'],
      support_url: "#{node['login_dot_gov']['domain_name']}/support",
      twilio_accounts: encrypted_config['twilio_accounts']
    })
  end

  cookbook_file "#{release_path}/certs/saml.crt" do
    action :create
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  file "#{release_path}/keys/saml.key.enc" do
    action :create
    content encrypted_config['saml.key.enc']
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
  end

  bundle_install do
    binstubs '/srv/idp/current/bin'
    deployment true
    jobs 3
    vendor '/srv/idp/shared/'
    without %w{deploy development test}
  end

  # install browserify
  execute 'npm install' do
  #  creates 'node_modules'
    cwd '/srv/idp/releases/chef'
  end

  rails do
    # for some reason you can't set the database name when using ruby block format. Perhaps it has
    # something to do with having the same name as the resource to which the block belongs.
    database({
      adapter: 'postgresql',
      database: encrypted_config['db_database'],
      username: encrypted_config['db_username'],
      host: encrypted_config['db_host'],
      password: encrypted_config['db_password']
    })
    rails_env node['login_dot_gov']['rails_env']
    secret_token node['login_dot_gov']['secret_token']
  end

  execute '/opt/ruby_build/builds/2.3.1/bin/bundle exec rake db:setup' do
    cwd '/srv/idp/releases/chef'
    environment({
      'RAILS_ENV' => "production"
    })
  end

  notifies :restart, "service[passenger]"
end

execute 'cp /srv/idp/releases/chef/config/application.yml /srv/idp/shared/config/'
execute 'cp /srv/idp/releases/chef/config/database.yml /srv/idp/shared/config/'
execute 'cp /srv/idp/releases/chef/certs/saml.crt /srv/idp/shared/certs/'
execute 'cp /srv/idp/releases/chef/keys/saml.key.enc /srv/idp/shared/keys/'
execute 'ln -nfs /srv/idp/releases/chef /srv/idp/current'
execute "chown -R #{node['login_dot_gov']['system_user']}: /srv"

file '/opt/nginx/conf/htpasswd' do
  content encrypted_config['http_basic_auth']
  notifies :restart, "service[passenger]"
end

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
template "/opt/nginx/conf/sites.d/idp.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: 'idp',
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions']
  })
end

execute "mount -o remount,noexec,nosuid,nodev /tmp"

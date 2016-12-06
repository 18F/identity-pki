execute "mount -o remount,exec,nosuid,nodev /tmp"

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

release_path = '/srv/idp/releases/chef'

directory release_path do
  recursive true
end

shared_dirs = [
  'bin',
  'certs',
  'config',
  'keys',
  'log',
  'public/assets',
  'public/system',
  'tmp/cache',
  'tmp/pids',
  'tmp/socket',
  'vendor/bundle'
]

shared_dirs.each do |dir|
  directory "/srv/idp/shared/#{dir}" do
    recursive true
  end
end

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

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

  bundle_install do
    binstubs '/srv/idp/shared/bin'
    user node['login_dot_gov']['system_user']
    deployment true
    jobs 3
    vendor '/srv/idp/shared/bundle'
    without %w{deploy development doc test}
  end

  # custom resource to install the IdP config files (app.yml, saml.crt, saml.key)
  login_dot_gov_idp_configs release_path do
    not_if { node['login_dot_gov']['setup_only'] }
  end

  # install node dependencies
  execute 'npm install' do
    # creates node_path
    cwd '/srv/idp/releases/chef'
    live_stream true
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
    secret_token node['login_dot_gov']['secret_key_base']
    not_if { node['login_dot_gov']['setup_only'] }
  end

  execute 'chown -R ubuntu: /home/ubuntu/.bundle /usr/local/src'

  execute '/opt/ruby_build/builds/2.3.3/bin/bundle exec rake db:create db:migrate db:seed --trace' do
    cwd '/srv/idp/releases/chef'
    environment({
      'RAILS_ENV' => "production"
    })
    live_stream true
    not_if { node['login_dot_gov']['setup_only'] }
  end

  if File.exist?("/etc/init.d/passenger")
    notifies(:restart, "service[passenger]")
    not_if { node['login_dot_gov']['setup_only'] }
  end
end

# cp generated configs from chef to the shared dir on first run
app_config = '/srv/idp/releases/chef/config/application.yml'
unless File.exist?(app_config) && File.symlink?(app_config) || node['login_dot_gov']['setup_only']
  execute 'cp /srv/idp/releases/chef/config/application.yml /srv/idp/shared/config/'
  execute 'cp /srv/idp/releases/chef/config/database.yml /srv/idp/shared/config/'
  execute 'cp /srv/idp/releases/chef/certs/saml.crt /srv/idp/shared/certs/'
  execute 'cp /srv/idp/releases/chef/keys/saml.key.enc /srv/idp/shared/keys/'
end

# symlink chef release to current dir
execute 'ln -fns /srv/idp/releases/chef/ /srv/idp/current'

# symlink shared folders to current dir
['bin', 'log'].each do |dir|
  directory "/srv/idp/current/#{dir}" do
    action :delete
    recursive true
  end
end

(shared_dirs-['certs', 'config', 'keys']).each do |dir|
  execute "ln -fns /srv/idp/shared/#{dir} /srv/idp/releases/chef/#{dir}" unless node['login_dot_gov']['setup_only']
end

# symlink shared files to current dir
shared_files = [
  'certs/saml.crt',
  'config/application.yml',
  'config/database.yml',
  'keys/saml.key.enc'
]

shared_files.each do |file|
  execute "ln -fns /srv/idp/shared/#{file} /srv/idp/releases/chef/#{file}" unless node['login_dot_gov']['setup_only']
end

execute "chown -R #{node['login_dot_gov']['system_user']}: /srv"

execute "mount -o remount,noexec,nosuid,nodev /tmp"

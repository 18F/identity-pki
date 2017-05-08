execute "mount -o remount,exec,nosuid,nodev /tmp"

release_path    = '/srv/idp/releases/chef'
shared_path     = '/srv/idp/shared'

package 'jq'

file '/root/.ssh/id_rsa.pub' do
  content Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]['jenkins_equifax_gem_pubkey']
  user  'root'
  group 'root'
  mode  '0600'
  subscribes :create, "application[#{release_path}]", :before
end

file '/root/.ssh/id_rsa' do
  content Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]['jenkins_equifax_gem_privkey']
  user  'root'
  group 'root'
  mode  '0600'
  subscribes :create, "application[#{release_path}]", :before
end

# create dir for AWS PostgreSQL combined CA cert bundle
directory '/usr/local/share/aws' do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

# add AWS PostgreSQL combined CA cert bundle
remote_file '/usr/local/share/aws/rds-combined-ca-bundle.pem' do
  action :create
  group 'root'
  mode 0755
  owner 'root'
  sensitive true # nothing sensitive but using to remove unnecessary output
  source 'https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem'
end

execute 'ssh-keyscan -H github.com > /etc/ssh/ssh_known_hosts'

execute 'update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100' do
  not_if { ::File.exists? '/usr/bin/node' }
end

directory release_path do
  recursive true
end

directory shared_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  recursive true
end

directory '/home/ubuntu/.bundle' do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
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
  directory "#{shared_path}/#{dir}" do
    owner node['login_dot_gov']['system_user']
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

  # branch is defined as an attribute or defaults to stages/<env>
  branch_name = node['login_dot_gov']['branch_name'] || "stages/#{node.chef_environment}"

  git do
    repository 'https://github.com/18F/identity-idp.git'
    user node['login_dot_gov']['system_user']
    revision branch_name
  end

  bundle_install do
    binstubs '/srv/idp/shared/bin'
    deployment true
    jobs 3
    vendor '/srv/idp/shared/bundle'
    without %w{deploy development doc test}
  end

  # custom resource to install the IdP config files (app.yml, saml.crt, saml.key)
  login_dot_gov_idp_configs release_path do
    not_if { node['login_dot_gov']['setup_only'] }
  end

  # custom resource to configure new relic (newrelic.yml)
  login_dot_gov_newrelic_config release_path do
    not_if { node['login_dot_gov']['setup_only'] }
    node.set['login_dot_gov']['app_friendly_name'] = "#{node.chef_environment}.#{node['login_dot_gov']['app_name']}"
  end

  # install node dependencies
  execute 'npm install' do
    # creates node_path
    cwd '/srv/idp/releases/chef'
  end

  rails do
    # for some reason you can't set the database name when using ruby block format. Perhaps it has
    # something to do with having the same name as the resource to which the block belongs.
    database({
      adapter: 'postgresql',
      database: encrypted_config['db_database_idp'],
      username: encrypted_config['db_username_idp'],
      host: encrypted_config['db_host_idp'],
      password: encrypted_config['db_password_idp'],
      sslmode: 'verify-full',
      sslrootcert: '/usr/local/share/aws/rds-combined-ca-bundle.pem'
    })
    rails_env node['login_dot_gov']['rails_env']
    secret_token node['login_dot_gov']['secret_key_base_idp']
    not_if { node['login_dot_gov']['setup_only'] }
  end

  execute 'chown -R ubuntu /home/ubuntu/.bundle /usr/local/src'

  execute "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec rake db:create db:migrate db:seed --trace" do
    cwd '/srv/idp/releases/chef'
    environment({
      'RAILS_ENV' => "production"
    })
    not_if { node['login_dot_gov']['setup_only'] }
  end

  if File.exist?("/etc/init.d/passenger")
    notifies(:restart, "service[passenger]")
    not_if { node['login_dot_gov']['setup_only'] }
  end
end

# cp generated configs from chef to the shared dir
app_config = {
  '/srv/idp/releases/chef/config/application.yml' => '/srv/idp/shared/config/',
  '/srv/idp/releases/chef/config/database.yml' => '/srv/idp/shared/config/',
  '/srv/idp/releases/chef/config/experiments.yml' => '/srv/idp/shared/config/',
  '/srv/idp/releases/chef/config/newrelic.yml' => '/srv/idp/shared/config/',
  '/srv/idp/releases/chef/certs/saml.crt' => '/srv/idp/shared/certs/',
  '/srv/idp/releases/chef/keys/saml.key.enc' => '/srv/idp/shared/keys/',
  '/srv/idp/releases/chef/keys/equifax_rsa' => '/srv/idp/shared/keys/'
}
app_config.keys.each do |config|
  unless File.exist?(config) && File.symlink?(config) || node['login_dot_gov']['setup_only']
    execute "cp #{config} #{app_config[config]}"
  end
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
  'config/experiments.yml',
  'config/newrelic.yml',
  'keys/equifax_rsa',
  'keys/saml.key.enc'
]

shared_files.each do |file|
  execute "ln -fns /srv/idp/shared/#{file} /srv/idp/releases/chef/#{file}" unless node['login_dot_gov']['setup_only']
end

execute "chown -R #{node['login_dot_gov']['system_user']}:nogroup /srv"

execute "mount -o remount,noexec,nosuid,nodev /tmp"

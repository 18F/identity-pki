execute "mount -o remount,exec,nosuid,nodev /tmp"

login_dot_gov_lets_encrypt 'dashboard'

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

base_dir = '/srv/dashboard'

%w{config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['system_user']
    recursive true
  end
end

execute "chown -R #{node['login_dot_gov']['system_user']}: #{base_dir}"
execute "chown -R #{node['login_dot_gov']['system_user']}: /opt/ruby_build"
execute "chown -R #{node['login_dot_gov']['system_user']}: /var/chef/cache"

template "#{base_dir}/shared/config/database.yml" do
  owner node['login_dot_gov']['system_user']
 # source 'nginx_server.conf.erb'
  variables({
      database: 'dashboard',
      username: encrypted_config['db_username'],
      host: encrypted_config['db_host'],
      password: encrypted_config['db_password']
  })
end

deploy "#{base_dir}" do
  action :deploy

  before_symlink do
    bundle = "/opt/ruby_build/builds/2.3.3/bin/bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test"
    assets = '/opt/ruby_build/builds/2.3.3/bin/bundle exec rake assets:precompile'

    [bundle, assets].each do |cmd|
      execute cmd do
        cwd release_path
        environment ({
          'RAILS_ENV' => 'production',
          'SECRET_KEY_BASE'=> encrypted_config['secret_key_base_dashboard'],
          'SMTP_ADDRESS' => encrypted_config['smtp_settings']['address'],
          'SMTP_DOMAIN' => node['set_fqdn'],
          'SMTP_PASSWORD' => encrypted_config['smtp_settings']['password'],
          'SMTP_USERNAME' => encrypted_config['smtp_settings']['user_name'],
        })
        user node['login_dot_gov']['system_user']
        live_stream true
      end
    end
  end

  repo 'https://github.com/18F/identity-dashboard.git'

  symlinks ({
    'vendor/bundle' => 'vendor/bundle',
    'config/database.yml' => 'config/database.yml',
    "log" => "log",
    "public/system" => "public/system",
    "tmp/pids" => "tmp/pids"
  })

  user 'ubuntu'
end

execute '/opt/ruby_build/builds/2.3.3/bin/bundle exec rake db:create --trace' do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
  live_stream true
end

file '/opt/nginx/conf/htpasswd' do
  content encrypted_config['http_basic_auth']
  notifies :restart, "service[passenger]"
end

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
template "/opt/nginx/conf/sites.d/dashboard.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: 'dashboard',
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions']
  })
end

execute "mount -o remount,noexec,nosuid,nodev /tmp"

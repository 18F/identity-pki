execute "mount -o remount,exec,nosuid,nodev /tmp"

login_dot_gov_lets_encrypt 'sp-rails'

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

base_dir = '/srv/sp-rails'

%w{config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['system_user']
    recursive true
  end
end

template "#{base_dir}/shared/config/secrets.yml" do
  action :create
  source 'secrets.yml.erb'
  manage_symlink_source true
  subscribes :create, 'resource[git]', :immediately
  user node['login_dot_gov']['system_user']

  variables({
    secret_key_base: encrypted_config['secret_key_base_rails'],
    saml_issuer: node['login_dot_gov']['sp_rails']['saml_issuer'],
    idp_sso_url: node['login_dot_gov']['sp_rails']['idp_sso_url'],
    idp_slo_url: node['login_dot_gov']['sp_rails']['idp_slo_url'],
    http_auth_username: node['login_dot_gov']['sp_rails']['http_auth_username'],
    http_auth_password: node['login_dot_gov']['sp_rails']['http_auth_password'],
    idp_cert_fingerprint: node['login_dot_gov']['sp_rails']['idp_cert_fingerprint']
  })
end

execute "chown -R #{node['login_dot_gov']['system_user']}: #{base_dir}"
execute "chown -R #{node['login_dot_gov']['system_user']}: /opt/ruby_build"
execute "chown -R #{node['login_dot_gov']['system_user']}: /var/chef/cache"

template "#{base_dir}/shared/config/database.yml" do
  owner node['login_dot_gov']['system_user']
 # source 'nginx_server.conf.erb'
  variables({
      database: 'sp_rails',
      username: encrypted_config['db_username'],
      host: encrypted_config['db_host'],
      password: encrypted_config['db_password']
  })
end

deploy '/srv/sp-rails' do
  action :deploy

  before_symlink do
    bundle = "/opt/ruby_build/builds/2.3.3/bin/bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test"
    assets = '/opt/ruby_build/builds/2.3.3/bin/bundle exec rake assets:precompile'

    [bundle, assets].each do |cmd|
      execute cmd do
        cwd release_path
        user 'ubuntu'
      end
    end
  end

  repo 'https://github.com/18F/identity-sp-rails.git'

  symlinks ({
    'vendor/bundle' => 'vendor/bundle',
    'config/database.yml' => 'config/database.yml',
    'config/secrets.yml' => 'config/secrets.yml',
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
template "/opt/nginx/conf/sites.d/sp-rails.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: 'sp-rails',
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions']
  })
end

execute "mount -o remount,noexec,nosuid,nodev /tmp"

execute "mount -o remount,exec,nosuid,nodev /tmp"

# setup postgres root config resource
psql_config 'configure postgres root cert'

app_name = 'sp-rails'

include_recipe 'login_dot_gov::dhparam'

base_dir = "/srv/#{app_name}"
deploy_dir = "#{base_dir}/current/public"

branch_name = node.fetch('login_dot_gov').fetch('branch_name', "stages/#{node.chef_environment}")

%w{cached-copy config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node.fetch(:passenger).fetch(:production).fetch(:user)
    recursive true
    subscribes :create, "deploy[/srv/#{app_name}]", :before
  end
end

full_domain = "#{node.chef_environment}.#{node.fetch('login_dot_gov').fetch('domain_name')}"

basic_auth_user_name = ConfigLoader.load_config_or_nil(node, "basic_auth_user_name")
basic_auth_password = ConfigLoader.load_config_or_nil(node, "basic_auth_password")

sp_rails_config = {
  'secret_key_base' => ConfigLoader.load_config(node, "secret_key_base_rails"),
  'saml_issuer' => node.fetch('login_dot_gov').fetch('sp_rails').fetch('saml_issuer'),
  'idp_sso_url' => "https://idp.#{full_domain}/api/saml/auth2018",
  'idp_slo_url' => "https://idp.#{full_domain}/api/saml/logout2018",
  'idp_cert_fingerprint' => node.fetch('login_dot_gov').fetch('sp_rails').fetch('idp_cert_fingerprint'),
  'acs_url' => "https://sp.#{full_domain}/auth/saml/callback",
}

if basic_auth_password
  sp_rails_config['http_auth_username'] = basic_auth_user_name
  sp_rails_config['http_auth_password'] = basic_auth_password
end

file "#{base_dir}/shared/config/secrets.yml" do
  action :create
  manage_symlink_source true
  sensitive true
  subscribes :create, 'resource[git]', :immediately
  user node['login_dot_gov']['system_user']

  content({'production' => sp_rails_config}.to_yaml)
end

# TODO: don't generate YAML with erb, that's an antipattern
template "#{base_dir}/shared/config/database.yml" do
  owner node['login_dot_gov']['system_user']
  sensitive true
  variables({
    database: 'sp_rails',
    username: ConfigLoader.load_config(node, "db_username_app"),
    host: ConfigLoader.load_config(node, "db_host_app"),
    password: ConfigLoader.load_config(node, "db_password_app"),
    sslmode: 'verify-full',
    sslrootcert: '/usr/local/share/aws/rds-combined-ca-bundle.pem',
  })
end

deploy "/srv/#{app_name}" do
  action :deploy

  before_symlink do
    bundle = "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test"
    assets = "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec rake assets:precompile"

    [bundle, assets].each do |cmd|
      execute cmd do
        cwd release_path
        #user 'ubuntu'
      end
    end
  end

  repo "https://github.com/18F/identity-#{app_name}.git"
  branch_name
  shallow_clone true
  keep_releases 1

  symlinks ({
    'vendor/bundle' => 'vendor/bundle',
    'config/database.yml' => 'config/database.yml',
    'config/secrets.yml' => 'config/secrets.yml',
    "log" => "log",
    "public/system" => "public/system",
    "tmp/pids" => "tmp/pids"
  })

  #user 'ubuntu'
end

execute "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec rake db:create db:migrate db:seed --trace" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
end

if basic_auth_password
  basic_auth_config 'generate basic auth config' do
    password basic_auth_password
    user_name basic_auth_user_name
  end
end

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
template "/opt/nginx/conf/sites.d/#{app_name}.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: app_name,
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    saml_env: node.chef_environment,
    security_group_exceptions: ConfigLoader.load_config(node, "security_group_exceptions"),
    server_aliases: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    server_name: "sp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
  })
end

directory "#{deploy_dir}/api" do
  owner node.fetch('login_dot_gov').fetch('system_user')
  recursive true
  action :create
end

login_dot_gov_deploy_info "#{deploy_dir}/api/deploy.json" do
  owner node.fetch('login_dot_gov').fetch('system_user')
  branch branch_name
end

execute "mount -o remount,noexec,nosuid,nodev /tmp"

execute "mount -o remount,exec,nosuid,nodev /tmp"

# setup postgres root config resource
psql_config 'configure postgres root cert'

app_name = 'dashboard'

dhparam = ConfigLoader.load_config(node, "dhparam")

# generate a stronger DHE parameter on first run
# see: https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html#Forward_Secrecy_&_Diffie_Hellman_Ephemeral_Parameters
execute "${node['login_dot_gov']['openssl']['binary']} dhparam -out dhparam.pem 4096" do
  creates '/etc/ssl/certs/dhparam.pem'
  cwd '/etc/ssl/certs'
  notifies :stop, "service[passenger]", :before
  only_if { dhparam == nil }
  sensitive true
end

file '/etc/ssl/certs/dhparam.pem' do
  content dhparam
  not_if { dhparam == nil }
  sensitive true
end

base_dir = "/srv/#{app_name}"
deploy_dir = "#{base_dir}/current/public"

basic_auth_enabled = !!ConfigLoader.load_config_or_nil(node, "basic_auth_user_name")

idp_url = "https://idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
if basic_auth_enabled
  basic_auth_username = ConfigLoader.load_config(node, "basic_auth_user_name")
  basic_auth_password = ConfigLoader.load_config(node, "basic_auth_password")
  idp_sp_url = "https://#{basic_auth_username}:#{basic_auth_password}@idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}/api/service_provider"
else
  idp_sp_url = "https://idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}/api/service_provider"
end
dashboard_url = "https://dashboard.#{node.chef_environment}.#{node.fetch('login_dot_gov').fetch('domain_name')}"

branch_name = node.fetch('login_dot_gov').fetch('branch_name', "stages/#{node.chef_environment}")

%w{cached-copy config log}.each do |dir|
  directory "#{base_dir}/shared/#{dir}" do
    group node['login_dot_gov']['system_user']
    owner node.fetch(:passenger).fetch(:production).fetch(:user)
    recursive true
    subscribes :create, "deploy[/srv/dashboard]", :before
  end
end

# TODO: don't generate YAML with erb, that's an antipattern
template "#{base_dir}/shared/config/database.yml" do
  owner node['login_dot_gov']['system_user']
  sensitive true
  variables({
    database: 'dashboard',
    username: ConfigLoader.load_config(node, "db_username_app"),
    host: ConfigLoader.load_config(node, "db_host_app"),
    password: ConfigLoader.load_config(node, "db_password_app"),
    sslmode: 'verify-full',
    sslrootcert: '/usr/local/share/aws/rds-combined-ca-bundle.pem'
  })
end

# custom resource to configure new relic (newrelic.yml)
login_dot_gov_newrelic_config "#{base_dir}/shared" do
  not_if { node['login_dot_gov']['setup_only'] }
  app_name "dashboard.#{node.chef_environment}.#{node.fetch('login_dot_gov').fetch('domain_name')}"
end

dashboard_config = {
  'admin_email' => 'partners@login.gov',
  'saml_name_id_format' => 'urn:oasis:names:tc:SAML:1.1:nameid-format:persistent',
  'dashboard_api_token' => ConfigLoader.load_config(node, "dashboard_api_token"),
  'idp_url' => idp_url,
  'login_env' => "#{node.chef_environment}",
  'idp_sp_url' => idp_sp_url,
  'saml_idp_fingerprint' => ConfigLoader.load_config_or_nil(node, "idp_cert_fingerprint") || node['login_dot_gov']['dashboard']['idp_cert_fingerprint'],
  'saml_idp_slo_url' => "#{idp_url}/api/saml/logout2018",
  'saml_idp_sso_url' => "#{idp_url}/api/saml/auth2018",
  'saml_sp_certificate' => ConfigLoader.load_config_or_nil(node, "dashboard_sp_certificate") || node['login_dot_gov']['dashboard']['sp_certificate'],
  'saml_sp_issuer' => dashboard_url,
  'saml_sp_private_key' => ConfigLoader.load_config_or_nil(node, "dashboard_sp_private_key") || node['login_dot_gov']['dashboard']['sp_private_key'],
  'saml_sp_private_key_password' => ConfigLoader.load_config_or_nil(node, "dashboard_sp_private_key_password") || node['login_dot_gov']['dashboard']['sp_private_key_password'],
  'secret_key_base' => ConfigLoader.load_config(node, "secret_key_base_dashboard"),
  'smtp_address' => 'smtp.mandrillapp.com', # TODO unused
  'smtp_domain' => dashboard_url, # TODO unused
  'smtp_password' => 'sekret', # TODO unused
  'smtp_username' => 'user', # TODO unused
  'mailer_domain' => dashboard_url,
}

if basic_auth_enabled
  dashboard_config['basic_auth_username'] = basic_auth_username
  dashboard_config['basic_auth_password'] = basic_auth_password
end

# Application configuration (application.yml)
# TODO: don't generate YAML with erb, that's an antipattern
file "#{base_dir}/shared/config/application.yml" do
  owner node['login_dot_gov']['system_user']
  sensitive true
  content({'production' => dashboard_config}.to_yaml)
  subscribes :create, 'deploy[/srv/dashboard]', :immediately
end

deploy "#{base_dir}" do
  action :deploy

  before_symlink do
    execute "cp #{base_dir}/shared/config/application.yml #{release_path}/config/application.yml"
    # cp generated configs from chef to the shared dir on first run
    app_config = "#{base_dir}/shared/config/secrets.yml"
    unless File.exist?(app_config) && File.symlink?(app_config) || node['login_dot_gov']['setup_only']
      execute "cp #{release_path}/config/secrets.yml #{base_dir}/shared/config"
    end

    cmds = [
      "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle config build.nokogiri --use-system-libraries",
      "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test",
      "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec rake assets:precompile",
    ]

    cmds.each do |cmd|
      execute cmd do
        cwd release_path
        environment ({
          'RAILS_ENV' => 'production',
          'DASHBOARD_SECRET_KEY_BASE'=> ConfigLoader.load_config(node, "secret_key_base_dashboard"),
        })
      end
    end
  end

  repo 'https://github.com/18F/identity-dashboard.git'
  branch branch_name
  shallow_clone true
  keep_releases 1
  
  symlinks ({
    'config/database.yml' => 'config/database.yml',
    'config/newrelic.yml' => 'config/newrelic.yml',
    'config/saml.yml' => 'config/saml.yml',
    'config/application.yml' => 'config/application.yml',
    "log" => "log",
    "public/system" => "public/system",
    "tmp/pids" => "tmp/pids"
  })

  #user 'ubuntu'
end

execute "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec rake db:create db:migrate --trace" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
  user node['login_dot_gov']['system_user']
end

if basic_auth_enabled
  basic_auth_config 'generate basic auth config' do
    password  "#{basic_auth_password}"
    user_name "#{basic_auth_username}"
  end
end

# Create a self-signed certificate for ALB to talk to. ALB does not verify
# hostnames or care about certificate expiration.
key_path = "/etc/ssl/private/#{app_name}-key.pem"
cert_path = "/etc/ssl/certs/#{app_name}-cert.pem"

# rely on instance_certificate cookbook being present to generate a self-signed
# keypair
link key_path do
  to node.fetch('instance_certificate').fetch('key_path')
end
link cert_path do
  to node.fetch('instance_certificate').fetch('cert_path')
end

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
template "/opt/nginx/conf/sites.d/dashboard.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: app_name,
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    saml_env: node.chef_environment,
    secret_key_base: ConfigLoader.load_config(node, "secret_key_base_dashboard"),
    security_group_exceptions: ConfigLoader.load_config(node, "security_group_exceptions"),
    server_name: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
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

# After doing the full deploy, we need to fully restart passenger in order for
# it to actually be running. This seems like a bug in our chef config. The main
# service[passenger] restart seems to attempt a graceful restart that doesn't
# actually work.
# TODO don't do this, figure out how to get passenger/nginx to be happy
Chef.event_handler do
  on :run_completed do
    Chef::Log.info('Starting handler for passenger restart hack')
    if system('pgrep -a "^Passenger"')
      Chef::Log.info('Found running Passenger process')
    else
      Chef::Log.warn('Restarting passenger as hack to finish startup')
      if system('service passenger restart')
        Chef::Log.warn('OK, restarting passenger succeeded')
      else
        Chef::Log.warn('FAIL, restarting passenger failed')
      end
    end
  end
end

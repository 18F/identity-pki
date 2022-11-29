# setup postgres root config resource
psql_config 'configure postgres root cert'

app_name = 'dashboard'
domain_name = node.fetch('login_dot_gov').fetch('domain_name')

include_recipe 'login_dot_gov::dhparam'

base_dir      = "/srv/#{app_name}"
deploy_dir    = "#{base_dir}/current/public"
idp_url       = "https://idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"
idp_sp_url    = "https://idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}/api/service_provider"
dashboard_url = "https://dashboard.#{node.chef_environment}.#{node.fetch('login_dot_gov').fetch('domain_name')}"

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

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

# TODO: stop using deprecated deploy resource
deploy "#{base_dir}" do
  action :deploy

  symlink_before_migrate({
    'config/database.yml' => 'config/database.yml',
    'config/application.yml' => 'config/application.yml',
    #'log' => 'log',
  })

  before_symlink do

    cmds = [
      "rbenv exec bundle config build.nokogiri --use-system-libraries",
      "rbenv exec bundle install --deployment --jobs 3 --path #{base_dir}/shared/bundle --without deploy development test",
      "yarn install --cache-folder .cache/yarn",
      "rbenv exec bundle exec rake assets:precompile"
    ]

    cmds.each do |cmd|
      execute cmd do
        cwd release_path
        environment ({
          'RAILS_ENV' => 'production',
        })
        #user node.fetch('login_dot_gov').fetch('system_user')
      end
    end
  end

  repo 'https://github.com/18F/identity-dashboard.git'
  branch deploy_branch
  shallow_clone true
  keep_releases 1

  #user node.fetch('login_dot_gov').fetch('system_user')
end

execute "chown-data-www" do
  command "chown -R #{node['login_dot_gov']['system_user']}: #{base_dir}"
  action :nothing
end

execute "rbenv exec bundle exec rake db:create db:migrate db:seed --trace" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
  user node['login_dot_gov']['system_user']
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

# nginx conf for app server

# 302 all sample app URLs to cloud.gov
# TODO: remove when we can get cloud.gov SSL certs allowing traffic from identitysandbox.gov
nginx_redirects = [
  {
    'server_name' => "#{node.chef_environment}-identity-saml-sinatra.app.cloud.gov",
    'redirect_server' => "sp-sinatra.#{node.chef_environment}.#{domain_name}"
  }
]

template "/opt/nginx/conf/sites.d/dashboard.login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'

  variables({
    app: app_name,
    domain: "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    passenger_ruby: lazy { Dir.chdir(deploy_dir) { shell_out!(%w{rbenv which ruby}).stdout.chomp } },
    server_name: "#{app_name}.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    nginx_redirects: nginx_redirects
  })
end

directory "#{deploy_dir}/api" do
  owner node.fetch('login_dot_gov').fetch('system_user')
  recursive true
  action :create
end

login_dot_gov_deploy_info "#{deploy_dir}/api/deploy.json" do
  owner node.fetch('login_dot_gov').fetch('system_user')
  branch deploy_branch
end

# set log directory permissions
directory "#{base_dir}/shared/log" do
    owner node.fetch('login_dot_gov').fetch('web_system_user')
    group node.fetch('login_dot_gov').fetch('web_system_user')
    mode '0775'
    recursive true
end


# After doing the full deploy, we want to ensure that passenger is up and
# running before the ELB starts trying to health check it. We've seen some
# cases where passenger takes too long to start up the process, fails two
# health checks, and the whole instance gets terminated.
prewarm_timeout = node.fetch('login_dot_gov').fetch('passenger_prewarm_timeout')
Chef.event_handler do
  on :run_completed do
    Chef::Log.info('Pre-warming passenger by sending an HTTP request')
    cmd = Mixlib::ShellOut.new('curl', '-sSIk', 'https://localhost', timeout: prewarm_timeout)
    cmd.run_command
    cmd.error!
    Chef::Log.info("Success:") if cmd.stdout.include?('HTTP/1.1 200 OK')
    Chef::Log.info("\n" + cmd.stdout)
    raise ShellCommandFailed unless cmd.stdout.include?('HTTP/1.1 200 OK')
  end
end
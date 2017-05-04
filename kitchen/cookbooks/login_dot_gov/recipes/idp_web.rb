encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

basic_auth_enabled = !encrypted_config['basic_auth_password'].nil?

if basic_auth_enabled
  basic_auth_config 'generate basic auth config' do
    password encrypted_config['basic_auth_password']
    user_name encrypted_config['basic_auth_user_name']
  end
else
  if %w(prod staging).include?(node.chef_environment)
    # When in prod or staging, issue warning that basic auth is disabled
    Chef::Log.warn 'Basic auth disabled'
  else
    # Raise exception if basic auth credentials are missing in other envs
    Chef::Log.fatal 'No basic auth credentials found'
    Chef::Log.fatal 'Only prod and staging may operate without basic auth'
    raise
  end
end

# branch is set by environment/node, otherwise use stages/env
branch_name = node['login_dot_gov']['branch_name'] || "stages/#{node.chef_environment}"
base_dir = '/srv/idp'
deploy_dir = "#{base_dir}/current/public"

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
app_name = 'idp'

domain_name = node.chef_environment == 'prod' ? 'secure.login.gov' : "#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}"

dhparam = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]["dhparam"]

# generate a stronger DHE parameter on first run
# see: https://raymii.org/s/tutorials/Strong_SSL_Security_On_nginx.html#Forward_Secrecy_&_Diffie_Hellman_Ephemeral_Parameters
execute "openssl dhparam -out dhparam.pem 4096" do
  creates "/etc/ssl/certs/#{app_name}-dhparam.pem"
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

template "/opt/nginx/conf/sites.d/login.gov.conf" do
  owner node['login_dot_gov']['system_user']
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: app_name,
    basic_auth: basic_auth_enabled,
    elb_cidr: node['login_dot_gov']['elb_cidr'],
    security_group_exceptions: encrypted_config['security_group_exceptions'],
    server_aliases: "idp.#{node.chef_environment}.#{node['login_dot_gov']['domain_name']}",
    server_name: domain_name
  })
end

directory "#{deploy_dir}/api" do
  owner node['login_dot_gov']['user']
  recursive true
  action :create
end

template "#{deploy_dir}/api/deploy.json" do
  owner node['login_dot_gov']['user']
  source 'deploy.json.erb'
  variables lazy { ({
    env: node.chef_environment,
    branch: branch_name,
    user: 'chef',
    sha: `cd #{base_dir}/releases/chef ; git rev-parse HEAD`.chomp,
    timestamp: ::Time.new.strftime("%Y%m%d%H%M%S")
  })}
end

execute "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/bundle exec whenever --update-crontab" do
  cwd "#{base_dir}/current"
  environment({
    'RAILS_ENV' => "production"
  })
  only_if { node.name == "idp1.0.#{node.chef_environment}" } # first idp host
end

# allow other execute permissions on all directories within the application folder
# https://www.phusionpassenger.com/library/admin/nginx/troubleshooting/ruby/#upon-accessing-the-web-app-nginx-reports-a-permission-denied-error
execute "chmod o+x -R /srv"

# need this now that passenger runs as nobody
execute "chown -R #{node[:passenger][:production][:user]} /srv/idp/shared/log"

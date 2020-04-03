if node.chef_environment != "prod" && ConfigLoader.load_config_or_nil(node, "basic_auth_password")
  basic_auth_enabled = true
else
  basic_auth_enabled = false
end

domain_name = node.fetch('login_dot_gov').fetch('domain_name')

# JSON.parse breaks if security_group_exceptions doesn't exist
begin
  security_group_exceptions = JSON.parse(ConfigLoader.load_config(node, "security_group_exceptions"))
rescue
  security_group_exceptions = []
end

if basic_auth_enabled
  basic_auth_config 'generate basic auth config' do
    password ConfigLoader.load_config(node, "basic_auth_password")
    user_name ConfigLoader.load_config(node, "basic_auth_user_name")
  end
else
  if %w(prod staging).include?(node.chef_environment)
    Chef::Log.info 'Basic auth disabled'
    # ensure that prod/staging are always run with login.gov as domain name
    unless domain_name == 'login.gov'
      Chef::Log.fatal 'prod/staging are supposed to be under login.gov'
      raise "Unexpected login_dot_gov domain_name attribute: #{domain_name.inspect}"
    end
  elsif domain_name == 'identitysandbox.gov'
    Chef::Log.info 'Basic auth disabled and domain is sandbox'
  else
    # Raise exception if basic auth credentials are missing in other envs
    Chef::Log.fatal 'No basic auth credentials found'
    Chef::Log.fatal 'Only prod and staging may operate without basic auth'
    raise 'Only prod and staging may operate without basic auth outside identitysandbox.gov'
  end
end

app_name = 'idp'

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

base_dir = '/srv/idp'
deploy_dir = "#{base_dir}/current/public"

# add nginx conf for app server
# TODO: JJG convert security_group_exceptions to hash so we can keep a note in both chef and nginx
#       configs as to why we added the exception.
# Prod uses secure.login.gov, all others use idp.*
if node.chef_environment == 'prod'
  server_name = 'secure.login.gov'
  nginx_redirects = nil
else
  nginx_redirects = [
    {
      'server_name' => "idp.#{node.chef_environment}.#{domain_name}",
      'redirect_server' => "#{node.chef_environment}.#{domain_name}"
    }
  ]
  server_name = nginx_redirects[0]['server_name']
end

include_recipe 'login_dot_gov::dhparam'

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

template '/opt/nginx/conf/sites.d/idp_web.conf' do
  notifies :restart, "service[passenger]"
  source 'nginx_server.conf.erb'
  variables({
    app: app_name,
    basic_auth: basic_auth_enabled,
    idp_web: true,
    passenger_ruby: lazy { Dir.chdir(deploy_dir) { shell_out!(%w{rbenv which ruby}).stdout.chomp } },
    security_group_exceptions: security_group_exceptions,
    server_aliases: nil,
    server_name: server_name,
    nginx_redirects: nginx_redirects
  })
end

file '/opt/nginx/conf/sites.d/login.gov.conf' do
  action :delete
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

# allow other execute permissions on all directories within the application folder
# TODO: check that this is needed
# https://www.phusionpassenger.com/library/admin/nginx/troubleshooting/ruby/#upon-accessing-the-web-app-nginx-reports-a-permission-denied-error
execute "chmod o+X -R /srv"

# need this now that passenger runs as nobody
execute "chown -R #{node[:passenger][:production][:user]} /srv/idp/shared/log"

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
    Chef::Log.info("Success:\n" + cmd.stdout)
  end
end

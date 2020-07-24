domain_name = node.fetch('login_dot_gov').fetch('domain_name')
app_name = 'idp'

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

base_dir = '/srv/idp'
deploy_dir = "#{base_dir}/current/public"

# nginx conf for idp
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
    idp_web: true,
    passenger_ruby: lazy { Dir.chdir(deploy_dir) { shell_out!(%w{rbenv which ruby}).stdout.chomp } },
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

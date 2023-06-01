domain_name = node.fetch('login_dot_gov').fetch('domain_name')
app_name = 'idp'

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

base_dir = '/srv/idp'
deploy_dir = "#{base_dir}/current/public"
release_path = '/srv/idp/releases/chef'

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

## Fixup and sync system and NGINX MIME types
nginx_mime_types = '/opt/nginx/conf/mime.types'
local_mime_types = '/usr/local/etc/mime.types'

if File.exist?(nginx_mime_types)
  # Add types not included in NGINX default
  ruby_block 'addMissingMimeTypes' do
    block do
      fe = Chef::Util::FileEdit.new(nginx_mime_types)
      fe.insert_line_after_match(
        /^\s*application\/vnd\.wap\.wmlc\s+wmlc;\s*$/,
        '    application/wasm                                 wasm;')
      fe.write_file
    end
    # Assume none of the above have been added if application/wasm has not
    not_if { File.readlines(nginx_mime_types).grep(/application\/wasm/).any? }
  end

  # Convert NGINX MIME types into a seondary mime.types file to ensure
  # AWS s3 sync gets the types right
  Chef::Log.info("Re-creating #{local_mime_types} from #{nginx_mime_types}")

  execute "egrep '^ +' #{nginx_mime_types} | " \
    "awk '{ print $1 \" \" $2 }' | " \
    "cut -d ';' -f 1 > #{local_mime_types}"
else
  Chef::Log.info("No #{nginx_mime_types} - synced asset MIME types may be wrong")
end

file '/etc/init.d/passenger' do
  action :nothing
  notifies(:restart, "service[passenger]")
  only_if { ::File.exist?('/etc/init.d/passenger') && !node['login_dot_gov']['setup_only'] }
end

# Fixes permissions and groups needed for passenger to actually run the application on the new hardened images
include_recipe 'login_dot_gov::fix_permissions'

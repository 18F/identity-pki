domain_name = node.fetch('login_dot_gov').fetch('domain_name')
app_name = 'reporting'

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch('identity-reporting-rails', default_branch)
# deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

base_dir = '/srv/reporting'
deploy_dir = "#{base_dir}/current/public"
release_path = "#{base_dir}/releases/chef"

# nginx conf for reporting
# Prod uses analytics.login.gov, all others use analytics.identitysandbox.gov
if node.chef_environment == 'prod'
  server_name = 'analytics.login.gov'
  nginx_redirects = nil
else
  nginx_redirects = [
    {
      'server_name' => "reporting.#{node.chef_environment}.#{domain_name}",
      'redirect_server' => "#{node.chef_environment}.#{domain_name}",
    },
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

template '/opt/nginx/conf/sites.d/reporting_worker.conf' do
  source 'nginx_worker_server.conf.erb'
  variables({
              app: app_name,
              server_name:,
              ssl_certificate: node.fetch('instance_certificate').fetch('cert_path'),
              ssl_certificate_key: node.fetch('instance_certificate').fetch('key_path'),
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
        %r{^\s*application/vnd\.wap\.wmlc\s+wmlc;\s*$},
        '    application/wasm                                 wasm;'
      )
      fe.write_file
    end
    # Assume none of the above have been added if application/wasm has not
    not_if { File.readlines(nginx_mime_types).grep(%r{application/wasm}).any? }
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
  notifies(:restart, 'service[passenger]')
  only_if { ::File.exist?('/etc/init.d/passenger') && !node['login_dot_gov']['setup_only'] }
end


web_system_user = node.fetch('login_dot_gov').fetch('web_system_user')

systemd_unit 'reporting-worker@0.service' do
  action [:create]

  content <<-EOM
# Dropped off by chef
# Systemd unit for reporting-worker

[Unit]
Description=Reporting Worker Runner Service (reporting-worker) - %i
PartOf=reporting-workers.target

[Service]
ExecStart=/bin/bash -c 'bundle exec good_job start --probe-port=7001'
EnvironmentFile=/etc/environment
WorkingDirectory=#{release_path}
User=#{web_system_user}
Group=#{web_system_user}

Restart=on-failure
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=reporting-workers

# attempt graceful stop first
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
  EOM
end

worker_service_descriptors = 'reporting-worker@0.service '

template '/etc/systemd/system/reporting-workers.target' do
  variables(worker_service_descriptors: worker_service_descriptors.strip)
end

# Fixes permissions and groups needed for passenger to actually run the application on the new hardened images
include_recipe 'login_dot_gov::fix_permissions'

execute 'reload daemon to pickup the target file' do
  command 'systemctl daemon-reload'
end

execute 'enable worker target' do
  command 'systemctl enable reporting-workers.target'
end

execute 'start worker target' do
  command 'systemctl start reporting-workers.target'
end

systemd_unit 'nginx.service' do
  action [:create]

  content <<-EOM
# Dropped off by Chef
# systemd unit for nginx without passenger

[Unit]
Description=reporting worker nginx service
After=syslog.target network-online.target remote-fs.target nss-lookup.target
Wants=network-online.target

[Service]
Type=forking
PIDFile=/var/run/nginx.pid
ExecStartPre=/opt/nginx/sbin/nginx -t
ExecStart=/opt/nginx/sbin/nginx
ExecReload=/opt/nginx/sbin/nginx -s reload
ExecStop=/bin/kill -s QUIT $MAINPID
PrivateTmp=true
User=root
Group=root

[install]
Wantedby=multi-user.target
  EOM
end

template '/etc/apparmor.d/usr.sbin.nginx' do
  cookbook 'login_dot_gov'
  source 'usr.sbin.nginx.erb'
  owner 'root'
  group 'root'
  mode '0755'
end

execute 'enable_nginx_apparmor' do
  command 'aa-complain /etc/apparmor.d/usr.sbin.nginx'
  notifies :restart, 'service[nginx]'
end

service 'nginx' do
  supports status: true, restart: true, reload: true
  action %i[enable start]
end


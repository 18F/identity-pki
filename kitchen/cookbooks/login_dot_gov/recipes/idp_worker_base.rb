# setup postgres root config resource
psql_config 'configure postgres CA bundle root cert'

release_path    = '/srv/idp/releases/chef'
shared_path     = '/srv/idp/shared'

# create dir for AWS PostgreSQL combined CA cert bundle
directory '/usr/local/share/aws' do
  owner 'root'
  group 'root'
  mode 0755
  recursive true
end

# add AWS PostgreSQL combined CA cert bundle
remote_file '/usr/local/share/aws/rds-combined-ca-bundle.pem' do
  action :create
  group 'root'
  mode 0755
  owner 'root'
  sensitive true # nothing sensitive but using to remove unnecessary output
  source 'https://truststore.pki.rds.amazonaws.com/global/global-bundle.pem'
end

directory release_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  recursive true
end

directory shared_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  recursive true
end

shared_dirs = [
  'bin',
  'certs',
  'config',
  'keys',
  'log',
  'tmp',
  'public/assets',
  'public/system',
  'vendor/bundle',
]

shared_dirs.each do |dir|
  directory "#{shared_path}/#{dir}" do
    action :create
    owner node.fetch('login_dot_gov').fetch('system_user')
    recursive true # TODO: remove?

    # Make log and pids directories group writeable by web user
    if ['log', 'tmp/pids'].include?(dir)
      group node.fetch('login_dot_gov').fetch('web_system_user')
      mode '0775'
    end
  end
end

app_name = 'idp'

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

git release_path do
  repository 'https://github.com/18F/identity-idp.git'
  depth 1
  user node['login_dot_gov']['system_user']
  revision deploy_branch
end

execute 'tag instance from git repo sha' do
  command "aws ec2 create-tags --region #{node['ec2']['region']} --resources #{node['ec2']['instance_id']} --tags Key=gitsha:worker,Value=$(cd #{release_path} && git rev-parse HEAD)"
  ignore_failure true
end

if ENV['TEST_KITCHEN']
  directory '/home/ubuntu/.bundle/cache' do
    action :delete
    recursive true
  end
end

# The build step runs bundle install, yarn install, etc.
execute 'deploy build step' do
  cwd '/srv/idp/releases/chef'

  # We need to have a secondary group of "github" in order to read the github
  # SSH key, but chef doesn't set secondary sgids when executing processes,
  # so we use sudo instead to get all the login secondary groups.
  # https://github.com/chef/chef/issues/6162
  command [
    'sudo', '-H', '-u', node.fetch('login_dot_gov').fetch('system_user'), './deploy/build'
  ]
  user 'root'
end

# Run the activate script from the repo, which is used to download app
# configs and set things up for the app to run. This has to run before
# deploy/build because rake assets:precompile needs the full database configs
# to be present.
execute 'deploy activate step' do
  cwd release_path
  # We need to have a secondary group of "github" in order to read the github
  # SSH key, but chef doesn't set secondary sgids when executing processes,
  # so we use sudo instead to get all the login secondary groups.
  # https://github.com/chef/chef/issues/6162
  command [
    'sudo', '-H', '-u', node.fetch('login_dot_gov').fetch('system_user'),
    './deploy/activate',
  ]
  user 'root'
end

# TODO: Attempt to download pre-compiled artifacts including assets,
# like the idp instances, to avoid re-compiling on every worker host
execute 'deploy build-post-config step' do
  cwd '/srv/idp/releases/chef'
  command [
    'sudo', '-H', '-u', node.fetch('login_dot_gov').fetch('system_user'),
    './deploy/build-post-config',
  ]
  user 'root'
end

# symlink chef release to current dir
link '/srv/idp/current' do
  to '/srv/idp/releases/chef'
end

# TODO rethink or remove these shared directory symlinks. This method of
# sharing is brittle and has rather unclear value. It would be better for the
# app to explicitly look for any shared files in the shared directories rather
# than implicitly relying on symlinks. Some of these symlinks don't even get
# created correctly because we don't pass -T to ln, so we end up with a symlink
# at tmp/cache/cache instead of the intended symlink at tmp/cache.
#
# symlink shared folders to current dir
['log'].each do |dir|
  directory "/srv/idp/current/#{dir}" do
    action :delete
    recursive true
  end
end
(shared_dirs - ['bin', 'certs', 'config', 'keys']).each do |dir|
  execute "ln -fns /srv/idp/shared/#{dir} /srv/idp/releases/chef/#{dir}" unless node['login_dot_gov']['setup_only']
end

system_user = node.fetch('login_dot_gov').fetch('web_system_user')

systemd_unit 'idp-worker@0.service' do
  action [:create]

  content <<-EOM
# Dropped off by chef
# Systemd unit for idp-worker

[Unit]
Description=IDP Worker Runner Service (idp-worker) - %i
PartOf=idp-workers.target

[Service]
ExecStart=/bin/bash -c 'bundle exec good_job start --probe-port=7001'
EnvironmentFile=/etc/environment
WorkingDirectory=#{release_path}
User=#{system_user}
Group=#{system_user}

Restart=on-failure
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=idp-workers

# attempt graceful stop first
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
  EOM
end

systemd_unit 'idp-worker@.service' do
  action [:create]

  content <<-EOM
# Dropped off by chef
# Systemd unit for idp-worker

[Unit]
Description=IDP Worker Runner Service (idp-worker) - %i
PartOf=idp-workers.target

[Service]
ExecStart=/bin/bash -c 'bundle exec good_job start'
EnvironmentFile=/etc/environment
WorkingDirectory=#{release_path}
User=#{system_user}
Group=#{system_user}

Restart=on-failure
StandardOutput=syslog
StandardError=syslog
SyslogIdentifier=idp-workers

# attempt graceful stop first
KillSignal=SIGINT

[Install]
WantedBy=multi-user.target
  EOM
end

worker_service_descriptors = ''
node.fetch('login_dot_gov').fetch('worker_count').times do |i|
  worker_service_descriptors << "idp-worker@#{i}.service "
end

template '/etc/systemd/system/idp-workers.target' do
  variables(worker_service_descriptors: worker_service_descriptors.strip)
end

# Fixes permissions and groups needed for passenger to actually run the application on the new hardened images
include_recipe 'login_dot_gov::fix_permissions'

execute 'reload daemon to pickup the target file' do
  command 'systemctl daemon-reload'
end

execute 'enable worker target' do
  command 'systemctl enable idp-workers.target'
end

execute 'start worker target' do
  command 'systemctl start idp-workers.target'
end

# create a self-signed certificate for alb to talk to. alb does not verify
# hostnames or care about certificate expiration.
key_path = "/etc/ssl/private/#{app_name}-key.pem"
cert_path = "/etc/ssl/certs/#{app_name}-cert.pem"


link key_path do
  to node.fetch('instance_certificate').fetch('key_path')
end
link cert_path do
  to node.fetch('instance_certificate').fetch('cert_path')
end


# configure nginx for health checks via reverse proxy
domain_name = node.fetch('login_dot_gov').fetch('domain_name')

if node.chef_environment == 'prod'
  server_name = 'worker.login.gov'
else
  server_name = "worker.#{node.chef_environment}.#{domain_name}"
end

template '/opt/nginx/conf/sites.d/idp_worker.conf' do
  source 'nginx_worker_server.conf.erb'
  variables({
    app: app_name,
    server_name: server_name,
  })
end

systemd_unit 'nginx.service' do
  action [:create]

  content <<-EOM
# Dropped off by Chef
# systemd unit for nginx

[Unit]
Description=idp worker nginx service
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

include_recipe 'login_dot_gov::dhparam'

template '/etc/apparmor.d/usr.sbin.nginx' do
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
  action [ :enable, :start ]
end

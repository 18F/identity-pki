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
  source 'https://s3.amazonaws.com/rds-downloads/rds-combined-ca-bundle.pem'
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
  'vendor/bundle'
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

if ENV['TEST_KITCHEN']
  directory '/home/ubuntu/.bundle/cache' do
    action :delete
    recursive true
  end
end

# worker
execute 'config idp bundler' do
  command "rbenv exec bundle config build.nokogiri --use-system-libraries"
  cwd release_path
end

execute 'run idp bundle' do
  command "rbenv exec bundle install --deployment --jobs 4 --path '/srv/idp/shared/bundle' --binstubs  '/srv/idp/shared/bundle/bin' --without 'deploy development doc test'"
  cwd release_path
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
    './deploy/activate'
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
(shared_dirs-['bin', 'certs', 'config', 'keys']).each do |dir|
  execute "ln -fns /srv/idp/shared/#{dir} /srv/idp/releases/chef/#{dir}" unless node['login_dot_gov']['setup_only']
end

system_user = node.fetch('login_dot_gov').fetch('web_system_user')

if node.fetch('login_dot_gov').fetch('idp_run_recurring_jobs')
  
else
  Chef::Log.info('idp_run_recurring_jobs is falsy, disabling idp-jobs.service')
  service_state = [:create, :disable, :stop]
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

execute 'reload daemon to pickup the target file' do
  command "systemctl daemon-reload"
end

execute 'enable worker target' do
  command "systemctl enable idp-workers.target"
end

execute 'start worker target' do
  command "systemctl start idp-workers.target"
end

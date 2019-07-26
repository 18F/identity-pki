include_recipe 'login_dot_gov::nodejs'

if node.fetch('login_dot_gov').fetch('cloudhsm_enabled')
  Chef::Log.info('CloudHSM is enabled')
  include_recipe 'login_dot_gov::cloudhsm'
else
  Chef::Log.info('CloudHSM is not enabled')
end

# setup postgres root config resource
psql_config 'configure postgres CA bundle root cert'

release_path    = '/srv/idp/releases/chef'
shared_path     = '/srv/idp/shared'

package 'jq'
case node[:platform_version]
when '16.04'
  package 'libcurl4-openssl-dev'
end

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

execute 'update-alternatives --install /usr/bin/node nodejs /usr/bin/nodejs 100' do
  not_if { ::File.exists? '/usr/bin/node' }
end

directory release_path do
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
  'public/assets',
  'public/system',
  'tmp/cache',
  'tmp/pids',
  'tmp/socket',
  'vendor/bundle'
]

shared_dirs.each do |dir|
  directory "#{shared_path}/#{dir}" do
    owner node.fetch('login_dot_gov').fetch('system_user')
    recursive true # TODO: remove?

    # Make log and pids directories group writeable by web user
    if ['log', 'tmp/pids'].include?(dir)
      group node.fetch('login_dot_gov').fetch('web_system_user')
      mode '0775'
    end
  end
end

# TODO: JJG consider migrating to chef deploy resource to stay in line with capistrano style:
# https://docs.chef.io/resource_deploy.html
application release_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']

  # branch is defined as an attribute or defaults to stages/<env>
  branch_name = node['login_dot_gov']['branch_name'] || "stages/#{node.chef_environment}"

  git do
    repository 'https://github.com/18F/identity-idp.git'
    user node['login_dot_gov']['system_user']
    revision branch_name
  end

  # custom resource to install the IdP config files (app.yml, saml.crt, saml.key)
  login_dot_gov_idp_configs shared_path do
    not_if { node['login_dot_gov']['setup_only'] }
    symlink_from release_path
  end

  # custom resource to configure new relic (newrelic.yml)
  login_dot_gov_newrelic_config shared_path do
    not_if { node['login_dot_gov']['setup_only'] }
    app_name "#{node.chef_environment}.#{node.fetch('login_dot_gov').fetch('domain_name')}"
    symlink_from release_path
  end

  # TODO: figure out why this hack is needed and remove it.
  # For some reason we are ending up with a root-owned directory
  # ~ubuntu/.bundle/cache but only when running kitchen-ec2. This causes the
  # bundle install in ./deploy/build to fail because it can't create new items
  # in the directory. Probably there are some bundle installs happening as root
  # with HOME still set to ~ubuntu.
  if ENV['TEST_KITCHEN']
    directory '/home/ubuntu/.bundle/cache' do
      action :delete
      recursive true
    end
  end

  # The build step runs bundle install, yarn install, rake assets:precompile,
  # etc.
  execute 'deploy build step' do
    cwd '/srv/idp/releases/chef'

    # We need to have a secondary group of "github" in order to read the github
    # SSH key, but chef doesn't set secondary sgids when executing processes,
    # so we use sudo instead to get all the login secondary groups.
    # https://github.com/chef/chef/issues/6162
    command [
      'sudo', '-H', '-u', node.fetch('login_dot_gov').fetch('system_user'),
      './deploy/build'
    ]
    user 'root'
  end

  # Run the activate script from the repo, which is used to download app
  # configs and set things up for the app to run. This has to run before
  # deploy/build because rake assets:precompile needs the full database configs
  # to be present.
  execute 'deploy activate step' do
    cwd '/srv/idp/releases/chef'
    command './deploy/activate'
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
  end

  rails do
    rails_env node['login_dot_gov']['rails_env']
    not_if { node['login_dot_gov']['setup_only'] }
    precompile_assets false
  end

  # ensure application.yml is readable by web user
  file '/srv/idp/releases/chef/config/application.yml' do
    group node.fetch('login_dot_gov').fetch('web_system_user')
  end

  execute 'deploy build-post-config step' do
    cwd '/srv/idp/releases/chef'
    command './deploy/build-post-config'
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
  end

  execute 'newrelic log deploy' do
    cwd '/srv/idp/releases/chef'
    command 'bundle exec newrelic deployments -r "$(git rev-parse HEAD)"'
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
  end

  if node.fetch('login_dot_gov').fetch('idp_run_migrations')
    Chef::Log.info('Running idp migrations')

    execute 'deploy migrate step' do
      cwd '/srv/idp/releases/chef'
      command './deploy/migrate && touch /tmp/ran-deploy-migrate'
      environment (node.fetch('login_dot_gov').fetch('allow_unsafe_migrations') ? { "SAFETY_ASSURED" => "1" } : nil )
      user node['login_dot_gov']['system_user']
      group node['login_dot_gov']['system_user']
      ignore_failure node.fetch('login_dot_gov').fetch('idp_migrations_ignore_failure')
    end

  else
    Chef::Log.info('Skipping idp migrations, idp_run_migrations is falsy')
  end

  if File.exist?("/etc/init.d/passenger")
    notifies(:restart, "service[passenger]")
    not_if { node['login_dot_gov']['setup_only'] }
  end
end

# create GPG binary key for use w/o importing
execute "gpg --dearmor < /srv/idp/shared/keys/equifax_gpg.pub > /srv/idp/shared/keys/equifax_gpg.pub.bin"
link "#{release_path}/keys/equifax_gpg.pub.bin" do
  to "#{shared_path}/keys/equifax_gpg.pub.bin"
  owner node.fetch('login_dot_gov').fetch('system_user')
  group node.fetch('login_dot_gov').fetch('system_user')
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

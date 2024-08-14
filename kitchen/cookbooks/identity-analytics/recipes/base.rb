# setup postgres root config resource
psql_config 'configure postgres CA bundle root cert'

parent_release_path = '/srv/reporting/releases'
release_path        = '/srv/reporting/releases/chef'
shared_path         = '/srv/reporting/shared'

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

directory parent_release_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  recursive true
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
  'public/assets',
  'public/system',
  'tmp/cache',
  'tmp/pids',
  'tmp/socket',
  'vendor/bundle',
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

app_name = 'reporting'

# TODO: JJG consider migrating to chef deploy resource to stay in line with capistrano style:
# https://docs.chef.io/resource_deploy.html
# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch('identity-reporting-rails', default_branch)
git_sha = shell_out("git ls-remote https://github.com/18F/identity-reporting-rails.git #{deploy_branch} | awk '{print $1}'").stdout.chomp

git release_path do
  repository 'https://github.com/18F/identity-reporting-rails.git'
  depth 1
  user node['login_dot_gov']['system_user']
  revision deploy_branch
end

execute 'tag instance from git repo sha' do
  command "aws ec2 create-tags --region #{node['ec2']['region']} --resources #{node['ec2']['instance_id']} --tags Key=gitsha:reporting,Value=$(cd #{release_path} && git rev-parse HEAD)"
  ignore_failure true
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
# etc. When installing from artifacts, bundle install has a different step
# so that it will expect gems to be vendored in a different directory
# rather than installed.
execute 'deploy build step' do
  cwd '/srv/reporting/releases/chef'

  # We need to have a secondary group of "github" in order to read the github
  # SSH key, but chef doesn't set secondary sgids when executing processes,
  # so we use sudo instead to get all the login secondary groups.
  # https://github.com/chef/chef/issues/6162
  command [
    'sudo', '-H', '-u', node.fetch('login_dot_gov').fetch('system_user'), './deploy/build',
  ]
  user 'root'
end

# Run the activate script from the repo, which is used to download app
# configs and set things up for the app to run. This has to run before
# deploy/build because rake assets:precompile needs the full database configs
# to be present.
execute 'deploy activate step' do
  cwd '/srv/reporting/releases/chef'
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

# ensure application.yml is readable by web user
file '/srv/reporting/releases/chef/config/application.yml' do
  group node.fetch('login_dot_gov').fetch('web_system_user')
end

execute 'newrelic log deploy' do
  cwd '/srv/reporting/releases/chef'
  command 'bundle exec rails newrelic:deployment'
  user node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  ignore_failure true
end

# symlink chef release to current dir
link '/srv/reporting/current' do
  to '/srv/reporting/releases/chef'
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
  directory "/srv/reporting/current/#{dir}" do
    action :delete
    recursive true
  end
end
(shared_dirs-['bin', 'certs', 'config', 'keys']).each do |dir|
  execute "ln -fns /srv/reporting/shared/#{dir} /srv/reporting/releases/chef/#{dir}" unless node['login_dot_gov']['setup_only']
end

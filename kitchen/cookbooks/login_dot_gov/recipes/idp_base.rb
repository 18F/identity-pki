# setup postgres root config resource
psql_config 'configure postgres CA bundle root cert'

parent_release_path = '/srv/idp/releases'
release_path        = '/srv/idp/releases/chef'
shared_path         = '/srv/idp/shared'

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

app_name = 'idp'

# TODO: JJG consider migrating to chef deploy resource to stay in line with capistrano style:
# https://docs.chef.io/resource_deploy.html
# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)
git_sha = shell_out("git ls-remote https://github.com/18F/identity-idp.git #{deploy_branch} | awk '{print $1}'").stdout.chomp
idp_artifacts_enabled = node['login_dot_gov']['idp_artifacts']
artifacts_bucket = node['login_dot_gov']['artifacts_bucket']
s3_artifact = "s3://#{artifacts_bucket}/#{node.chef_environment}/#{git_sha}.idp.tar.gz"
artifacts_downloaded = lambda { File.exist?('/srv/idp/releases/idp.tar.gz') }
artifacts_unzipped = lambda { File.exist?('/srv/idp/releases/artifacts-downloaded') }

# Attempts to download and extract an IDP artifact with the most recent SHA on the deploy branch
# into `/srv/idp/releases/chef`.
if idp_artifacts_enabled
  execute 'download artifacts' do
    cwd '/srv/idp/releases'
    command [
      'aws', 's3', 'cp', "#{Shellwords.shellescape(s3_artifact)}", 'idp.tar.gz'
    ]

    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
    ignore_failure true
  end

  execute 'unzip artifacts' do
    cwd '/srv/idp/releases'
    command [
      'tar', '-xzf', 'idp.tar.gz', '-C', 'chef'
    ]
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
    only_if { artifacts_downloaded.call }
    ignore_failure true
  end

  execute 'mark artifacts as downloaded successfully' do
    cwd '/srv/idp/releases'
    command [
      'touch', '/srv/idp/releases/artifacts-downloaded'
    ]
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
    only_if { artifacts_downloaded.call }
    ignore_failure true
  end
end

execute 'tag instance from artifact sha' do
  command "aws ec2 create-tags --region #{node['ec2']['region']} --resources #{node['ec2']['instance_id']} --tags Key=gitsha:idp,Value=#{git_sha}"
  only_if { artifacts_unzipped.call }
end

git release_path do
  repository 'https://github.com/18F/identity-idp.git'
  depth 1
  user node['login_dot_gov']['system_user']
  revision deploy_branch
  not_if { artifacts_unzipped.call }
end

execute 'tag instance from git repo sha' do
  command "aws ec2 create-tags --region #{node['ec2']['region']} --resources #{node['ec2']['instance_id']} --tags Key=gitsha:idp,Value=$(cd #{release_path} && git rev-parse HEAD)"
  only_if { idp_artifacts_enabled && !artifacts_unzipped.call }
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
  cwd '/srv/idp/releases/chef'

  # We need to have a secondary group of "github" in order to read the github
  # SSH key, but chef doesn't set secondary sgids when executing processes,
  # so we use sudo instead to get all the login secondary groups.
  # https://github.com/chef/chef/issues/6162
  command [
    'sudo', '-H', '-u', node.fetch('login_dot_gov').fetch('system_user'), './deploy/build'
  ]
  user 'root'
  only_if { !idp_artifacts_enabled || !artifacts_unzipped.call }
end

# If artifact was downloaded, we instruct the IDP to install its Ruby/JS dependencies
# using the vendored dependencies without any HTTP requests.
execute 'deploy build step with artifacts' do
  cwd '/srv/idp/releases/chef'

  command [
    'sudo', 'IDP_LOCAL_DEPENDENCIES=true', '-H', '-u', node.fetch('login_dot_gov').fetch('system_user'), './deploy/build'
  ]
  user 'root'
  only_if { idp_artifacts_enabled && artifacts_unzipped.call }
end

execute 'link large static files' do
  cwd '/srv/idp/releases/chef'

  command "test -f /srv/idp/shared/geo_data/GeoLite2-City.mmdb && test -f /srv/idp/shared/pwned_passwords/pwned_passwords.txt && \
  ln -s /srv/idp/shared/geo_data/GeoLite2-City.mmdb ./geo_data/GeoLite2-City.mmdb && \
  ln -s /srv/idp/shared/pwned_passwords/pwned_passwords.txt ./pwned_passwords/pwned_passwords.txt && \
  chmod -c 644 ./geo_data/GeoLite2-City.mmdb ./pwned_passwords/pwned_passwords.txt"

  ignore_failure true
end

# Run the activate script from the repo, which is used to download app
# configs and set things up for the app to run. This has to run before
# deploy/build because rake assets:precompile needs the full database configs
# to be present.
execute 'deploy activate step' do
  cwd '/srv/idp/releases/chef'
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

# ensure application.yml is readable by web user
file '/srv/idp/releases/chef/config/application.yml' do
  group node.fetch('login_dot_gov').fetch('web_system_user')
end

execute 'deploy build-post-config step' do
  cwd '/srv/idp/releases/chef'
  command [
    'sudo', '-H', '-u', node.fetch('login_dot_gov').fetch('system_user'),
    './deploy/build-post-config'
  ]
  user 'root'
  not_if { artifacts_unzipped.call }
end

execute 'newrelic log deploy' do
  cwd '/srv/idp/releases/chef'
  command 'bundle exec rails newrelic:deployment'
  user node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  ignore_failure true
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

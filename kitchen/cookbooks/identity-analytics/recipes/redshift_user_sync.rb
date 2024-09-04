identity_devops_repo = '/etc/login.gov/repos/identity-devops'
bundler_path = "#{identity_devops_repo}/.bundle"
metric_namespace = "Analytics/#{node.chef_environment}"
user_sync_metric_name = "UserSyncSuccess"
reshift_sync_command = [
  "cd #{identity_devops_repo} &&",
  "./bin/data-warehouse/users/sync.sh",
  "#{metric_namespace} #{user_sync_metric_name} 2>&1",
  "| logger --id=$$ -t data-warehouse/users/sync.sh"
].join(' ')

directory 'Sync Directory' do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  mode 0o777
  path '/usersync'
end

directory 'Bundle Directory' do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']
  mode 0o777
  path bundler_path
end

execute 'identity-devops bundle config' do
  cwd identity_devops_repo
  user node['login_dot_gov']['system_user']
  command [
    'bundle config set --local deployment true &&',
    'bundle config set --local without development test &&',
    "bundle config set --local path #{bundler_path}",
  ].join(' ')
  environment({'HOME' => '/home/appinstall'})
end

execute 'Redshift User Sync Bundle Install' do
  cwd identity_devops_repo
  user node['login_dot_gov']['system_user']
  command 'bundle install'
  environment({'HOME' => '/home/appinstall'})
end

execute 'Run Redshift User Sync' do
  cwd identity_devops_repo
  user node['login_dot_gov']['system_user']
  command reshift_sync_command
  only_if { node.fetch('identity-analytics').fetch('user_sync_cron_enable')}
  environment({'HOME' => '/home/appinstall'})
end

cron_d 'run_redshift_usersync_hourly' do
  action :create
  predefined_value '@hourly'
  user node['login_dot_gov']['system_user']
  command reshift_sync_command
  only_if { node.fetch('identity-analytics').fetch('user_sync_cron_enable')}
  environment({'HOME' => '/home/appinstall'})
end

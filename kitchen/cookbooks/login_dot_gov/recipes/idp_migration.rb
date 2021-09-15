domain_name = node.fetch('login_dot_gov').fetch('domain_name')
app_name = 'idp'

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

base_dir = '/srv/idp'
deploy_dir = "#{base_dir}/current/public"
release_path = '/srv/idp/releases/chef'

application release_path do
  owner node['login_dot_gov']['system_user']
  group node['login_dot_gov']['system_user']

  # deploy_branch defaults to stages/<env>
  # unless deploy_branch.identity-#{app_name} is specifically set otherwise
  default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
  deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)
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

  static_bucket = node.fetch('login_dot_gov').fetch('static_bucket')
  if static_bucket && node.fetch('login_dot_gov').fetch('idp_sync_static')
    Chef::Log.info("Syncronizing IdP assets and packs to #{static_bucket}")

    execute 'deploy sync static assets step' do
      # Sync based on size only (not create time) and ignore sprockets manifest
      command "aws s3 sync --size-only --exclude '.sprockets-manifest-*.json' #{release_path}/public/assets s3://#{static_bucket}/assets"
      user node['login_dot_gov']['system_user']
      group node['login_dot_gov']['system_user']
      ignore_failure node.fetch('login_dot_gov').fetch('idp_sync_static_ignore_failure')
    end

    execute 'deploy sync static packs step' do
      command "aws s3 sync --size-only #{release_path}/public/packs s3://#{static_bucket}/packs"
      user node['login_dot_gov']['system_user']
      group node['login_dot_gov']['system_user']
      ignore_failure node.fetch('login_dot_gov').fetch('idp_sync_static_ignore_failure')
    end
  else
    Chef::Log.info('Skipping assets sync - idp_sync_static or static_bucket are falsy')
  end
end

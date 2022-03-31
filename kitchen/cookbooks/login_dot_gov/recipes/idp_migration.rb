domain_name = node.fetch('login_dot_gov').fetch('domain_name')
app_name = 'idp'

# deploy_branch defaults to stages/<env>
# unless deploy_branch.identity-#{app_name} is specifically set otherwise
default_branch = node.fetch('login_dot_gov').fetch('deploy_branch_default')
deploy_branch = node.fetch('login_dot_gov').fetch('deploy_branch').fetch("identity-#{app_name}", default_branch)

base_dir = '/srv/idp'
deploy_dir = "#{base_dir}/current/public"
release_path = '/srv/idp/releases/chef'

idp_artifacts_enabled = node['login_dot_gov']['idp_artifacts']
artifacts_bucket = node['login_dot_gov']['artifacts_bucket']
artifacts_downloaded = lambda { File.exist?('/srv/idp/releases/artifacts-downloaded') }

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
static_cdn_max_age = node.fetch('login_dot_gov').fetch('static_cdn_max_age')
if static_bucket && node.fetch('login_dot_gov').fetch('idp_sync_static')
  Chef::Log.info("Syncronizing IdP assets and packs to #{static_bucket}")

  execute 'deploy sync static assets step' do
    # Sync based on size only (not create time) and ignore sprockets manifest
    command "aws s3 sync --size-only --cache-control max-age=#{static_cdn_max_age} --exclude '.sprockets-manifest-*.json' #{release_path}/public/assets s3://#{static_bucket}/assets"
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
    ignore_failure node.fetch('login_dot_gov').fetch('idp_sync_static_ignore_failure')
  end

  execute 'deploy sync static packs step' do
    command "aws s3 sync --size-only --cache-control max-age=#{static_cdn_max_age} --exclude 'manifest.json' #{release_path}/public/packs s3://#{static_bucket}/packs"
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
    ignore_failure node.fetch('login_dot_gov').fetch('idp_sync_static_ignore_failure')
  end

  execute 'deploy sync static packs manifest.json step' do
    command "aws s3 cp #{release_path}/public/packs/manifest.json s3://#{static_bucket}/packs/manifest.json"
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
    ignore_failure node.fetch('login_dot_gov').fetch('idp_sync_static_ignore_failure')
  end
else
  Chef::Log.info('Skipping assets sync - idp_sync_static or static_bucket are falsy')
end

if idp_artifacts_enabled
  execute 'generate artifact step' do
    cwd '/srv/idp/releases'
    user 'root'
    command [
      # The config/*.yml files and certs/sp are symlinks from the cloned identity-idp-config repo that are created during deploy/activate. They must be excluded to avoid colliding with future runs of deploy/activate for the artifact.
      # config/application.yml must be excluded because it could contain secrets. geo_data and pwned_passwords are excluded because they are large and are downloaded from S3 by the deploy/activate script.
      # tmp and node_modules/.cache are excluded because they aren't needed and are large.
      "make -C chef build_artifact ARTIFACT_DESTINATION_FILE='../idp.tar.gz' GZIP_COMMAND=pigz"
    ]
    not_if { artifacts_downloaded.call }
  end

  execute 'upload artifacts' do
    cwd '/srv/idp/releases'

    # Upload the tar file to S3 so that it can be downloaded by future IDP instances
    # The git SHA is pulled from the cloned repository to ensure it is the correct SHA.
    command "aws s3 cp idp.tar.gz s3://#{artifacts_bucket}/#{node.chef_environment}/$(cd chef && git rev-parse HEAD).idp.tar.gz"
    not_if { artifacts_downloaded.call }
  end
end

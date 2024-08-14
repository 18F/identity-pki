domain_name = node.fetch('login_dot_gov').fetch('domain_name')
app_name = 'reporting'

file '/etc/login.gov/info/role' do
  content 'analytics'
  mode '0644'
  owner 'root'
  group 'root'
end

include_recipe 'identity-analytics::pgbouncer_autoconfig'
include_recipe 'identity-analytics::base'

base_dir = '/srv/reporting'
release_path = "#{base_dir}/releases/chef"

# nginx conf for reporting
# Prod uses secure.login.gov, all others use reporting.*
if node.fetch('identity-analytics').fetch('reporting_run_migrations')
  Chef::Log.info('Running analytics migrations')

  execute 'deploy migrate step' do
    cwd release_path
    command './deploy/migrate && touch /tmp/ran-deploy-migrate'
    environment (node.fetch('identity-analytics').fetch('allow_unsafe_migrations') ? { "SAFETY_ASSURED" => "1" } : nil )
    user node['login_dot_gov']['system_user']
    group node['login_dot_gov']['system_user']
    ignore_failure node.fetch('identity-analytics').fetch('reporting_migrations_ignore_failure')
  end
else
  Chef::Log.info('Skipping analytics migrations, analytics_run_migrations is falsy')
end

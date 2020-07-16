property :name, String

property :symlink_from, String

property :app_name, String, default: '<default_app_name>'

action :create do
  license_key = Chef::Recipe::ConfigLoader.load_config(node, "newrelic_license_key")

  directory "#{new_resource.name}/config" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['system_user']
    recursive true
  end

  file "#{new_resource.name}/config/newrelic.yml" do
    action :create
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
    sensitive true
    content({
      'production' => {
        'agent_enabled' => node['login_dot_gov']['agent_enabled'],
        'app_name' => new_resource.app_name,
        'host' => node['login_dot_gov']['new_relic_host'],
        'audit_log' => {
          'enabled' => node['login_dot_gov']['audit_log_enabled'],
        },
        'browser_monitoring' => {
          'auto_instrument' => node['login_dot_gov']['auto_instrument'],
        },
        'error_collector' => {
          'enabled' => node['login_dot_gov']['error_collector_enabled'],
          'capture_source' => node['login_dot_gov']['capture_error_source'],
          'ignore_errors' => [
            'ActionController::RoutingError',
            'ActionController::BadRequest',
          ].join(','),
        },
        'license_key' => license_key,
        'log_level' => node['login_dot_gov']['log_level'],
        'monitor_mode' => node['login_dot_gov']['monitor_mode'],
        'transaction_tracer' => {
          'enabled' => node['login_dot_gov']['transaction_tracer_enabled'],
          'record_sql' => node['login_dot_gov']['record_sql'],
          'stack_trace_threshold' => node['login_dot_gov']['stack_trace_threshold'],
          'transaction_threshold' => node['login_dot_gov']['transaction_threshold'],
        },
        'proxy_host' => node['login_dot_gov']['proxy_server'],
        'proxy_port' => node['login_dot_gov']['proxy_port'],
      }
    }.to_yaml)
  end

  # create symlink if requested
  if new_resource.symlink_from
    link "#{new_resource.symlink_from}/config/newrelic.yml" do
      to "#{new_resource.name}/config/newrelic.yml"
      owner node.fetch('login_dot_gov').fetch('system_user')
      group node.fetch('login_dot_gov').fetch('system_user')
    end
  end
end

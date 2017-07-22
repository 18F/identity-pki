property :name, String, default: '/srv/idp' # defaults to IdP path

property :app_name, String, default: '<default_app_name>'

action :create do
  license_key = Chef::Recipe::ConfigLoader.load_config(node, "newrelic_license_key")

  directory "#{name}/config" do
    group node['login_dot_gov']['system_user']
    owner node['login_dot_gov']['system_user']
    recursive true
  end

  template "#{name}/config/newrelic.yml" do
    action :create
    manage_symlink_source true
    subscribes :create, 'resource[git]', :immediately
    user node['login_dot_gov']['system_user']
    sensitive true
    variables({
      agent_enabled: node['login_dot_gov']['agent_enabled'],
      app_name: app_name,
      audit_log_enabled: node['login_dot_gov']['audit_log_enabled'],
      auto_instrument: node['login_dot_gov']['auto_instrument'],
      capture_error_source: node['login_dot_gov']['capture_error_source'],
      error_collector_enabled: node['login_dot_gov']['error_collector_enabled'],
      license_key: license_key,
      log_level: node['login_dot_gov']['log_level'],
      monitor_mode: node['login_dot_gov']['monitor_mode'],
      transaction_tracer_enabled: node['login_dot_gov']['transaction_tracer_enabled'],
      record_sql: node['login_dot_gov']['record_sql'],
      stack_trace_threshold: node['login_dot_gov']['stack_trace_threshold'],
      transaction_threshold: node['login_dot_gov']['transaction_threshold'],
      proxy_host: node['login_dot_gov']['proxy_addr'],
      proxy_port: node['login_dot_gov']['proxy_port']
    })
  end
end

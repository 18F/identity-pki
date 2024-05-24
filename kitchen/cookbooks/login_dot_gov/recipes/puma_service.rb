# Any value of RUBY_YJIT_ENABLE will enable it, even false, so we have to avoid including the ENV
# variable if we do not want to enable it.
ruby_yjit = node.fetch('login_dot_gov').fetch('idp_ruby_yjit_enabled')
remote_address_header = node.fetch(:puma)[:remote_address_header]
puma_log_path = node.fetch(:puma)[:log_path]
puma_log_err_path = node.fetch(:puma)[:log_err_path]

remote_address_config = if remote_address_header != nil
                          "REMOTE_ADDRESS_HEADER='#{remote_address_header}'"
                        else
                          nil
                        end
puma_log_config = if puma_log_path != nil && puma_log_err_path != nil
                        <<~CONFIG
PUMA_LOG='#{puma_log_path}'
PUMA_LOG_ERR='#{puma_log_err_path}'
                        CONFIG
                        else
                          nil
                        end
primary_role = File.read('/etc/login.gov/info/role').chomp

if primary_role != 'worker'
  # Set values used by config/puma.rb and YJIT
  file '/etc/default/puma' do
    content <<-EOM
  PUMA_WORKER_CONCURRENCY=#{(node.fetch('cpu').fetch('total')).round}
  #{puma_log_config.nil? ? "" : puma_log_config}
  #{remote_address_config.nil? ? "" : remote_address_config}
  #{ruby_yjit == true || ruby_yjit == 'true' ? "RUBY_YJIT_ENABLE='true'" : ""}
    EOM
  end

  template '/etc/apparmor.d/puma' do
    source 'puma_apparmor.erb'
    variables({
      bundle_path: node.fetch(:puma).fetch(:bin_path),
    })
    owner 'root'
    group 'root'
    mode '0755'
  end

  execute 'enable_puma_apparmor' do
    command 'aa-complain /etc/apparmor.d/puma'
  end

  template '/usr/local/bin/cw-custom-logs' do
    source 'cw-custom-puma-logs.erb'
    owner 'root'
    group 'root'
    mode '0755'
    variables({
                environmentName: File.read('/etc/login.gov/info/env').chomp,
                instanceId: node['ec2']['instance_id'],
                instanceType: node['ec2']['instance_type'],
                roleName: primary_role,
              })
  end

  template '/etc/cron.d/cw-custom-logs' do
    source 'cw-custom-logs-cron.erb'
    owner 'root'
    group 'root'
    mode '0644'
  end

  if primary_role == 'idp'
    template '/usr/local/bin/id-puma-restart' do
      source 'id-puma-restart.erb'
      owner 'root'
      group 'root'
      mode '0755'
    end
  end
end

# replacement for passenger recipe
# passenger is built as part of base image

native_support_dir = node.fetch(:passenger).fetch(:production).fetch(:path) + '/passenger-native-support'

# Any value of RUBY_YJIT_ENABLE will enable it, even false, so we have to avoid including the ENV
# variable if we do not want to enable it.
ruby_yjit = node.fetch('login_dot_gov').fetch('idp_ruby_yjit_enabled')

file '/etc/default/passenger' do
  content <<-EOM
export http_proxy=#{Chef::Config['http_proxy']}
export https_proxy=#{Chef::Config['https_proxy']}
export no_proxy=#{Chef::Config['no_proxy']}
#{ruby_yjit == true || ruby_yjit == 'true' ? "export RUBY_YJIT_ENABLE='true'" : ""}
export PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR='#{native_support_dir}'
  EOM
end

service 'passenger' do
  action :nothing
  supports restart: true, status: true
end

primary_role = File.read('/etc/login.gov/info/role').chomp

passenger_enabled = primary_role != 'worker' && ((primary_role == 'idp' && node['login_dot_gov']['use_idp_puma'] != true) ||
  (primary_role == 'app' && node['login_dot_gov']['use_dashboard_puma'] != true) ||
  (primary_role == 'pivcac' && node['login_dot_gov']['use_pivcac_puma'] != true))

if passenger_enabled && primary_role != 'worker'
  template '/etc/apparmor.d/opt.ruby_build.shims.passenger' do
    source 'opt.ruby_build.shims.passenger.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end

  execute 'enable_passenger_apparmor' do
    command 'aa-complain /etc/apparmor.d/opt.ruby_build.shims.passenger'
  end

  template '/usr/local/bin/cw-custom-logs' do
    source 'cw-custom-passenger-logs.erb'
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

  template '/usr/local/bin/id-passenger-restart' do
    source 'id-passenger-restart.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end
end

# replacement for passenger recipe
# passenger is built as part of base image

native_support_dir = node.fetch(:passenger).fetch(:production).fetch(:path) + '/passenger-native-support'

file '/etc/default/passenger' do
  content <<-EOM
export http_proxy=#{Chef::Config['http_proxy']}
export https_proxy=#{Chef::Config['https_proxy']}
export no_proxy=#{Chef::Config['no_proxy']}
export PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR='#{native_support_dir}'
  EOM
end


service 'passenger' do
  action :nothing
  supports restart: true, status: true
end

nginx_conf     = '/opt/nginx/conf/nginx.conf'
cpu_count      = node.fetch('cpu').fetch('total')
primary_role = File.read('/etc/login.gov/info/role').chomp

if primary_role != 'worker'
  execute 'scale nginx worker count with instance cpu count' do
    command "sed -i -e 's/worker_processes.*/worker_processes #{cpu_count};/' #{nginx_conf}"
    notifies :restart, 'service[passenger]'
  end

  execute 'scale passenger pool size with instance cpu count' do
    command "sed -i -e 's/passenger_max_pool_size.*/passenger_max_pool_size #{cpu_count * 2};/' #{nginx_conf}"
    notifies :restart, 'service[passenger]'
  end

  execute 'scale passenger pool size with instance cpu count' do
    command "sed -i -e 's/passenger_min_instances.*/passenger_min_instances #{cpu_count * 2};/' #{nginx_conf}"
    notifies :restart, 'service[passenger]'
  end

  template '/usr/local/bin/cw-custom-logs' do
    source 'cw-custom-logs.erb'
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
end

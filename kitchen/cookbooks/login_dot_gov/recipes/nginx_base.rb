primary_role = File.read('/etc/login.gov/info/role').chomp

# Only enable passenger for IDP, Dashboard and PIVCAC when not configured for Puma
passenger_enabled = ['app', 'pivcac', 'idp'].include?(primary_role)

template "/opt/nginx/aws_v4_cidrs.txt" do
  source 'aws_ipv4_cidrs.txt'
  mode '644'
end

template "/opt/nginx/aws_v6_cidrs.txt" do
  source 'aws_ipv6_cidrs.txt'
  mode '644'
end

template "/opt/nginx/conf/nginx.conf" do
  source 'nginx_base_server.conf.erb'
  mode '644'
  variables(
    :log_path => '/var/log/nginx',
    limit_connections: node['login_dot_gov']['nginx_limit_connections'],
    worker_processes: node['login_dot_gov']['nginx_worker_processes'],
    worker_connections: node['login_dot_gov']['nginx_worker_connections'],
    nofile_limit: node['login_dot_gov']['nginx_worker_connections'] * 2,
    log_client_ssl: false,
    ruby_path: node.fetch(:identity_shared_attributes).fetch(:rbenv_root) + '/shims/ruby',
    pidfile: "/var/run/nginx.pid",
    passenger_user: node.fetch(:identity_shared_attributes).fetch(:production_user),
    passenger_enabled: passenger_enabled,
    passenger_pool_idle_time: 0,
    passenger_max_request_queue_size: 512,
    passenger_max_instances_per_app: 0,
    passenger_pool_size: node.fetch('cpu').fetch('total') * 4,
    passenger_root: passenger_enabled && lazy do
                     # dynamically compute passenger root at converge using rbenv
                     shell_out!(%w{rbenv exec passenger-config --root}).stdout.chomp
    end,
    cloudfront_cidrs_v4: lazy {
      # Grab Cloudfront IPv4 CIDR list from the CLOUDFRONT_ORIGIN_FACING subset
      # of Amazon IPv4 ranges
      File.read('/opt/nginx/aws_v4_cidrs.txt').split("\n")
    },
    cloudfront_cidrs_v6: lazy {
      # Grab Cloudfront IPv6 CIDR list from the CLOUDFRONT subset of Amazon IPv6 ranges
      # (There is no seperate CLOUDFRONT_ORIGIN_FACING set for IPv6)
      File.read('/opt/nginx/aws_v6_cidrs.txt').split("\n")
    }
  )
end

service 'passenger' do
  action [:enable]
end

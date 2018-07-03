default[:passenger][:production][:path] = '/opt/nginx'

cache_dir = '/var/cache/chef' # must match default['login_dot_gov']['cache_dir']
openssl_version = '1.0.2o' # must match the one in default['login_dot_gov']['openssl']['binary']
openssl_srcpath = "#{cache_dir}/openssl-#{openssl_version}"
default[:passenger][:production][:configure_flags] = "--with-ipv6 --with-http_stub_status_module --with-http_ssl_module --with-http_realip_module --with-openssl=#{openssl_srcpath}"
default[:passenger][:production][:log_path] = '/var/log/nginx'

# Tune these for your environment, see:
# http://www.modrails.com/documentation/Users%20guide%20Nginx.html#_resource_control_and_optimization_options
default[:passenger][:production][:max_pool_size] = node.fetch('cpu').fetch('total') * 2
default[:passenger][:production][:min_instances] = node.fetch('cpu').fetch('total')
default[:passenger][:production][:pool_idle_time] = 0
default[:passenger][:production][:max_instances_per_app] = 0
default[:passenger][:production][:limit_connections] = true

# a list of URL's to pre-start.
default[:passenger][:production][:pre_start] = []
default[:passenger][:production][:sendfile] = true
default[:passenger][:production][:tcp_nopush] = false

# Nginx's default is 0, but we don't want that.
default[:passenger][:production][:keepalive_timeout] = '60 50'
default[:passenger][:production][:gzip] = true
default[:passenger][:production][:worker_connections] = 1024

# Enable the status server on 127.0.0.1
default[:passenger][:production][:status_server] = true

default[:passenger][:production][:version] = '5.3.1'
default[:passenger][:production][:user] = 'websrv' # must match default['login_dot_gov']['web_system_user']

# Allow our local /16 to proxy setting X-Forwarded-For
# This is a little broad, but because we expect security group rules to prevent
# anyone except our trusted ALB from connecting anyway, we don't really care
# who is able to set X-Forwarded-For headers.
default[:passenger][:production][:realip_from_cidr] = node.fetch(:cloud).fetch('local_ipv4').split('.')[0..1].join('.') + '.0.0/16'

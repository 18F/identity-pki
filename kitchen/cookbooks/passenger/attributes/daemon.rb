default[:passenger][:production][:path] = '/opt/nginx'
default[:passenger][:production][:configure_flags] = '--with-ipv6 --with-http_stub_status_module --with-http_ssl_module --with-http_realip_module'
default[:passenger][:production][:log_path] = '/var/log/nginx'

# Tune these for your environment, see:
# http://www.modrails.com/documentation/Users%20guide%20Nginx.html#_resource_control_and_optimization_options
if node.has_key?('cpu') 
  default[:passenger][:production][:max_pool_size] = node.default.fetch('cpu').fetch('total')
  default[:passenger][:production][:min_instances] = node.default.fetch('cpu').fetch('total')
else
  default[:passenger][:production][:max_pool_size] = 6
  default[:passenger][:production][:min_instances] = 1
end

default[:passenger][:production][:pool_idle_time] = 0
default[:passenger][:production][:max_instances_per_app] = 0
default[:passenger][:production][:limit_connections] = true

# a list of URL's to pre-start.
default[:passenger][:production][:pre_start] = []
default[:passenger][:production][:sendfile] = true
default[:passenger][:production][:tcp_nopush] = false

# Nginx's default is 0, but we don't want that.
default[:passenger][:production][:keepalive_timeout] = '5 5'
default[:passenger][:production][:gzip] = true
default[:passenger][:production][:worker_connections] = 1024

# Enable the status server on 127.0.0.1
default[:passenger][:production][:status_server] = true

default[:passenger][:production][:version] = '5.0.30'
default[:passenger][:production][:user] = 'nobody'

# Allow our local /16 to proxy setting X-Forwarded-For
# This is a little broad, but because we expect security group rules to prevent
# anyone except our trusted ALB from connecting anyway, we don't really care
# who is able to set X-Forwarded-For headers.
default[:passenger][:production][:realip_from_cidr] = node.fetch(:cloud).fetch('local_ipv4').split('.')[0..1].join('.') + '.0.0/16'

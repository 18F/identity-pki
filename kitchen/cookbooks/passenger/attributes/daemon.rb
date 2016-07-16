default[:passenger][:production][:path] = '/opt/nginx'
default[:passenger][:production][:configure_flags] = '--with-ipv6 --with-http_stub_status_module --with-http_ssl_module'
default[:passenger][:production][:log_path] = '/var/log/passenger/'

# Tune these for your environment, see:
# http://www.modrails.com/documentation/Users%20guide%20Nginx.html#_resource_control_and_optimization_options
default[:passenger][:production][:max_pool_size] = 6
default[:passenger][:production][:min_instances] = 1
default[:passenger][:production][:pool_idle_time] = 0
default[:passenger][:production][:max_instances_per_app] = 0
# a list of URL's to pre-start.
default[:passenger][:production][:pre_start] = []

default[:passenger][:production][:sendfile] = true
default[:passenger][:production][:tcp_nopush] = false
# Nginx's default is 0, but we don't want that.
default[:passenger][:production][:keepalive_timeout] = 65
default[:passenger][:production][:gzip] = true
default[:passenger][:production][:worker_connections] = 1024

# Enable the status server on 127.0.0.1
default[:passenger][:production][:status_server] = true

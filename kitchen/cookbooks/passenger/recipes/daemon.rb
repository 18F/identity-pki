#
# Cookbook Name:: passenger
# Recipe:: production

include_recipe "passenger::install"

package "curl"
if ['ubuntu', 'debian'].member? node[:platform]
  ['libcurl4-openssl-dev','libpcre3-dev'].each do |pkg|
    package pkg
  end
end

nginx_path = node[:passenger][:production][:path]

bash "install passenger/nginx" do
  user "root"
  code <<-EOH
  /opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/passenger-install-nginx-module --auto --auto-download --prefix="#{nginx_path}" --extra-configure-flags="#{node[:passenger][:production][:configure_flags]}"
  EOH
  not_if "test -e #{nginx_path}"
  not_if "test -e /usr/local/rvm"
end

bash "install passenger/nginx from rvm" do
  user "root"
  code <<-EOH
  /usr/local/bin/rvm exec passenger-install-nginx-module --auto --auto-download --prefix="#{nginx_path}" --extra-configure-flags="#{node[:passenger][:production][:configure_flags]}"
  EOH
  not_if "test -e #{nginx_path}"
  only_if "test -e /usr/local/rvm"
end

log_path = node[:passenger][:production][:log_path]

directory log_path do
  mode 0755
  action :create
end

directory "#{nginx_path}/conf/conf.d" do
  mode 0755
  action :create
  recursive true
  notifies :reload, 'service[passenger]'
end

directory "#{nginx_path}/conf/sites.d" do
  mode 0755
  action :create
  recursive true
  notifies :reload, 'service[passenger]'
end

template "#{nginx_path}/conf/nginx.conf" do
  source "nginx.conf.erb"
  owner "root"
  group "root"
  mode 0644
  sensitive true
  variables(
    :log_path => log_path,
    :passenger_root => "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/lib/ruby/gems/2.3.0/gems/passenger-#{node[:passenger][:production][:version]}",
    :ruby_path => "/opt/ruby_build/builds/#{node['login_dot_gov']['ruby_version']}/bin/ruby",
    :passenger => node[:passenger][:production],
    :pidfile => "/var/run/nginx.pid",
    :passenger_user => node[:passenger][:production][:user]
  )
  notifies :run, 'bash[config_patch]'
end

cookbook_file "#{nginx_path}/status-map.conf" do
  source "status-map.conf"
  mode "0644"
end

cookbook_file "#{nginx_path}/sbin/config_patch.sh" do
  owner "root"
  group "root"
  mode 0755
end

bash "config_patch" do
  # The big problem is that we can't compute the gem install path
  # because we don't know what ruby version we're being installed
  # on if RVM is present.
#  only_if "grep '##PASSENGER_ROOT##' #{nginx_path}/conf/nginx.conf"
  user "root"
  code "#{nginx_path}/sbin/config_patch.sh #{nginx_path}/conf/nginx.conf"
  notifies :reload, 'service[passenger]'
end

template "/etc/init.d/passenger" do
  source "passenger.init.erb"
  owner "root"
  group "root"
  mode 0755
  sensitive true
  variables(
    :pidfile => "#{nginx_path}/nginx.pid",
    :nginx_path => nginx_path
  )
end

if node[:passenger][:production][:status_server]
  cookbook_file "#{nginx_path}/conf/sites.d/status.conf" do
    source "status.conf"
    mode "0644"
  end
end

# set permissions on nginx folder to the same as nginx user:group
# TODO: don't chown this whole path
directory "#{nginx_path}" do
  owner 'nobody'
  group 'nogroup'
  recursive true
  action :create
end

# allow other execute permissions on all directories within the application folder
# https://www.phusionpassenger.com/library/admin/nginx/troubleshooting/ruby/#upon-accessing-the-web-app-nginx-reports-a-permission-denied-error
# TODO: actually fix the issue rather than relying on this chmod hammer
execute "chmod -R a+X #{nginx_path}"
execute "chmod -R a+rX #{nginx_path}/conf"

service "passenger" do
  service_name "passenger"
  reload_command "#{nginx_path}/sbin/nginx -s reload"
  start_command "#{nginx_path}/sbin/nginx"
  stop_command "#{nginx_path}/sbin/nginx -s stop"
  status_command "curl http://localhost/nginx_status"
  supports [ :start, :stop, :reload, :status, :enable ]
  action [ :enable, :start ]
  pattern "nginx: master"
end

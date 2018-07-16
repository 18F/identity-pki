#
# Cookbook Name:: passenger
# Recipe:: production

include_recipe "passenger::install"

package "curl"
['libcurl4-openssl-dev', 'libpcre3-dev'].each do |pkg|
  package pkg
end

nginx_path = node.fetch(:passenger).fetch(:production).fetch(:path)

bash "install passenger/nginx" do
  code <<-EOH
  set -eux
  rbenv exec passenger-install-nginx-module --auto --auto-download --prefix="#{nginx_path}" --extra-configure-flags="#{node[:passenger][:production][:configure_flags]}"
  rbenv rehash
  EOH
  not_if "test -e #{nginx_path}/sbin/nginx"
end

log_path = node[:passenger][:production][:log_path]

directory log_path do
  mode 0750
  action :create
  owner 'root'
  group 'adm'
end

nginx_path_logs = nginx_path + '/logs'

execute 'backup existing nginx logs' do
  command %W{mv -vT #{nginx_path_logs} #{nginx_path_logs + '.backup'}}
  only_if { File.directory?(nginx_path_logs) && !File.symlink?(nginx_path_logs) }
end

# make a symlink from nginx/logs/ to our desired log_path
link nginx_path_logs do
  to log_path
end

directory "#{nginx_path}/conf/conf.d" do
  mode 0755
  action :create
  recursive true
  notifies :restart, 'service[passenger]'
end

directory "#{nginx_path}/conf/sites.d" do
  mode 0755
  action :create
  recursive true
  notifies :restart, 'service[passenger]'
end

native_support_dir = node.fetch(:passenger).fetch(:production).fetch(:native_support_dir)

# directory for compiling native ruby version modules
directory native_support_dir do
  mode '0755'
end

cookbook_file "#{nginx_path}/compile-passenger-module" do
  mode '0755'
  source 'compile-passenger-module'
  sensitive true # not actually sensitive, but verbose
end

execute 'compile passenger modules for all available ruby versions' do
  command %W[#{nginx_path}/compile-passenger-module ALL]
  environment(
    'PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR' => native_support_dir,
  )
end

cookbook_file "#{nginx_path}/conf/status-map.conf" do
  source "status-map.conf"
  mode "0644"
end

extend Chef::Mixin::ShellOut

template "#{nginx_path}/conf/nginx.conf" do
  source 'nginx.conf.erb'
  mode '644'
  variables(
    :log_path => log_path,
    passenger_root: lazy {
      # dynamically compute passenger root at converge using rbenv
      shell_out!(%w{rbenv exec passenger-config --root}).stdout
    },
    ruby_path: node.fetch('login_dot_gov').fetch('rbenv_shims_ruby'),
    :passenger => node[:passenger][:production],
    :pidfile => "/var/run/nginx.pid",
    :passenger_user => node[:passenger][:production][:user]
  )
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

# set proxy environment variables in passenger
# could alternatively source /etc/profile.d/proxy-config.sh, but it won't exist
# if the proxy isn't enabled
file "/etc/default/passenger" do
  content <<-EOM
export http_proxy='#{node.fetch('login_dot_gov').fetch('http_proxy')}'
export https_proxy='#{node.fetch('login_dot_gov').fetch('https_proxy')}'
export no_proxy='#{node.fetch('login_dot_gov').fetch('no_proxy')}'
export PASSENGER_NATIVE_SUPPORT_OUTPUT_DIR='#{native_support_dir}'
  EOM
end

if node[:passenger][:production][:status_server]
  cookbook_file "#{nginx_path}/conf/sites.d/status.conf" do
    source "status.conf"
    mode "0644"
  end
end

service 'passenger' do
  action [:enable, :start]
end

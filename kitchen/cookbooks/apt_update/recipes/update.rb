#
# Cookbook Name:: apt_update
# Recipe:: update
apt_update "update ubuntu machine in #{node.chef_environment}" do
  action :update
end

#
# Cookbook Name:: passenger
# Recipe:: install

gem_package "passenger/system" do
  gem_binary node.fetch('login_dot_gov').fetch('rbenv_shims_gem')
  package_name 'passenger'
  version node[:passenger][:production][:version]
end

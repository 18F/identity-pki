#
# Cookbook Name:: passenger
# Recipe:: install

gem_package "passenger/system" do
  package_name 'passenger'
  gem_binary '/opt/ruby_build/builds/2.3.1/bin/gem'
  not_if "test -e /usr/local/bin/rvm-gem.sh"
end

gem_package "passenger/rvm" do
  package_name 'passenger'
  gem_binary "/usr/local/bin/rvm-gem.sh"
  only_if "test -e /usr/local/bin/rvm-gem.sh"
end

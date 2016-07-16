include_recipe 'ruby_build'

# install ruby
ruby_runtime node['login_dot_gov']['ruby_version']

# add to users path
template '/etc/environment' do
  mode '0755'
end

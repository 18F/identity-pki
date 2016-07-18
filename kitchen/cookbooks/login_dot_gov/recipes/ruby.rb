ENV['TMPDIR'] = '/usr/local/src' # mv due to noexec on /tmp mountpoint

include_recipe 'ruby_build'

# install ruby
ruby_runtime node['login_dot_gov']['ruby_version']

execute "chown -R #{node['login_dot_gov']['system_user']}:adm /opt/ruby_build"

# add to users path
template '/etc/environment' do
  mode '0755'
end

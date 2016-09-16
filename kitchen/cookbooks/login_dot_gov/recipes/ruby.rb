# add to users path
template '/etc/environment' do
  mode '0755'
  subscribes :run, 'execute[ruby-build install]', :delayed
end

#execute 'source /etc/environment'

# install ruby
ruby_runtime node['login_dot_gov']['ruby_version'] do
  provider :ruby_build
end

execute "chown -R #{node['login_dot_gov']['system_user']}:adm /opt/ruby_build"

users_manage "#{node.chef_environment}" do
  action [:create]
  data_bag 'users'
  not_if { ::File.exist?('/etc/login.gov/info/auto-scaled') }
end

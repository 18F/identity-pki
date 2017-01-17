users_manage "#{node.chef_environment}" do
  action [:create]
  data_bag 'users'
end

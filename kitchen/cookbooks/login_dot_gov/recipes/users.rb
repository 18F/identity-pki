users_manage "#{node.chef_environment}" do
  action [:create]
  data_bag 'users'
  # identity-devops-private creates unix users on auto-scaled instances
  not_if { node['provisioner']['auto-scaled'] }
end

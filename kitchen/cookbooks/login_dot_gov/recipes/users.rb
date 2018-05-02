users_manage "#{node.chef_environment}" do
  action [:create]
  data_bag 'users'
  # identity-devops-private creates unix users on auto-scaled instances
  not_if { node.fetch('provisioner', {'auto-scaled' => false}).fetch('auto-scaled') }
end

# create app service user
user node.fetch('login_dot_gov').fetch('system_user') do
  home '/nonexistent'
  shell '/usr/sbin/nologin'
  system true
end
# create web service user
user node.fetch('login_dot_gov').fetch('web_system_user') do
  home '/nonexistent'
  shell '/usr/sbin/nologin'
  system true
end

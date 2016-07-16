users_manage 'adm' do
  action [:remove, :create]
end

managed_users = node['login_dot_gov']['dev_users'] << node['login_dot_gov']['system_user']

managed_users.each do |user|
  users_manage user do
    data_bag 'users'
  end
end

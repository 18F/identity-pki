package 'monit'

service 'monit' do
  action :nothing
end

service 'sidekiq' do
  action :nothing
  restart_command '/usr/bin/monit restart sidekiq_idp_production0'
  start_command '/usr/bin/monit start sidekiq_idp_production0'
  status_command '/usr/bin/monit status'
  stop_command '/usr/bin/monit stop sidekiq_idp_production0'
end

encrypted_config = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]

template "/home/ubuntu/.bash_profile" do
  owner node['login_dot_gov']['system_user']
  variables({
    sp_name: '18f',
    sp_pass: encrypted_config['db_password']
  })
end

template '/etc/monit/monitrc' do
  notifies :restart, 'service[monit]'
end

template '/etc/monit/conf.d/sidekiq_idp_production.conf' do
  notifies :restart, 'service[sidekiq]'
end

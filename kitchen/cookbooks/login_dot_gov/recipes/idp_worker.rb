package 'monit'

service 'monit' do
  action :start
end

template '/etc/monit/monitrc' do
  notifies :restart, 'service[monit]', :immediately
end

template '/etc/monit/conf.d/sidekiq_idp_production.conf' do
  notifies :restart, 'service[monit]', :immediately
  variables({
    ruby_version: node['login_dot_gov']['ruby_version']
  })
end

execute 'sleep 1'

service 'sidekiq' do
  action :restart
  restart_command '/usr/bin/monit restart sidekiq_idp_production0'
  start_command '/usr/bin/monit start sidekiq_idp_production0'
  status_command '/usr/bin/monit status'
  stop_command '/usr/bin/monit stop sidekiq_idp_production0'
end

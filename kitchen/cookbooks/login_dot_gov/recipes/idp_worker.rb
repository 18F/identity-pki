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
    bundle_cmd_path: node.fetch('login_dot_gov').fetch('default_ruby_path') + '/bin/bundle'
  })
end

# Action nothing means that this won't restart unless it's explicitly notified.
# We already trigger a monit restart above when sidekiq_idp_production.conf is
# modified, so keeping both of these restarts was leading to multiple sidekiq
# processes running. https://github.com/18F/identity-devops-private/issues/365
service 'sidekiq' do
  action :nothing
  restart_command '/usr/bin/monit restart sidekiq_idp_production0'
  start_command '/usr/bin/monit start sidekiq_idp_production0'
  status_command '/usr/bin/monit status'
  stop_command '/usr/bin/monit stop sidekiq_idp_production0'
end

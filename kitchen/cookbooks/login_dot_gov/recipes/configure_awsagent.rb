template '/var/awslogs/etc/awslogs.conf' do
    source 'awslogs.conf.erb'
    owner 'root'
    group 'root'
    mode 0644
    variables ({
      :environmentName => node.chef_environment
   })
    notifies :restart, 'service[awslogs]', :delayed
 end

 service 'awslogs' do
    action [:enable, :start]
    supports :restart => true, :status => true, :start => true, :stop => true
 end

 #inspector agent proxy configuration
 template '/etc/init.d/awsagent.env' do
  source 'awsagent.env.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables ({
    proxy_url: node.fetch('login_dot_gov').fetch('http_proxy'),
    no_proxy: node.fetch('login_dot_gov').fetch('no_proxy_hosts'),
  })
  notifies :restart, 'service[awsagent]', :immediate
end

service 'awsagent' do
  action [:enable, :start]
  supports :restart => true, :start => true, :stop => true
end

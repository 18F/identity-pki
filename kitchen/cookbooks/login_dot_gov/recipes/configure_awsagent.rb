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
template '/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json' do
  only_if { ::File.exist?('/opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent') }
  source 'amazon-cloudwatch-agent.json.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables ({
    :environmentName => node.chef_environment
  })
  notifies :restart, 'service[amazon-cloudwatch-agent]', :delayed
end

service 'amazon-cloudwatch-agent' do
  action :nothing
  supports :restart => true, :status => true, :start => true, :stop => true
end

#aws ssm agent proxy configuration
directory "/etc/systemd/system/snap.amazon-ssm-agent.amazon-ssm-agent.service.d" do
  owner owner 'root'
  group group 'root'
  mode '0755'
end

template '/etc/systemd/system/snap.amazon-ssm-agent.amazon-ssm-agent.service.d/override.conf' do
  source 'aws_ssmagent.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
  variables ({
    proxy_url: node.fetch('login_dot_gov').fetch('http_proxy'),
    no_proxy: node.fetch('login_dot_gov').fetch('no_proxy'),
  })
  notifies :restart, 'service[snap.amazon-ssm-agent.amazon-ssm-agent]', :delayed
end
 
service 'snap.amazon-ssm-agent.amazon-ssm-agent' do
  supports :restart => true, :start=> true, :stop => true
end

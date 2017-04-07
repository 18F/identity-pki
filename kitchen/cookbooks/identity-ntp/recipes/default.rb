package 'ntp' do
  action :upgrade
end

template '/etc/ntp.conf' do
  source 'ntp.conf.erb'
  owner 'root'
  group 'root'
  mode 0644
end

service 'ntp' do
  action [ :enable, :start ]
end

execute 'restart-ntp-if-no-peers' do
  command 'true'
  not_if "/usr/bin/ntpdc -c peers | egrep -v '============|remote.*local.*st' | awk '{print $5}' | grep -v 0"
  notifies :restart, 'service[ntp]'
end

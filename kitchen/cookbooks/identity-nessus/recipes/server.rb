# nessus .deb file is provisioned by terraform

# declare service for nessusd
service 'nessusd' do
  restart_command '/etc/init.d/nessusd restart'
  start_command '/etc/init.d/nessusd start'
  status_command '/etc/init.d/nessusd status'
  stop_command '/etc/init.d/nessusd stop'
end

# install dpkg
dpkg_package 'Nessus' do
  action :install
  source "/root/Nessus_amd64.deb"
  notifies :start, 'service[nessusd]'
end

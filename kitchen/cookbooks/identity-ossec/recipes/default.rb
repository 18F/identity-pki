#
# Cookbook Name:: identity-ossec
# Recipe:: default
#
# Copyright 2017, YOUR_COMPANY_NAME
#
# All rights reserved - Do Not Redistribute
#

include_recipe 'ossec'

execute '/var/ossec/bin/ossec-control enable client-syslog' do
  not_if "ps gaxuwww | grep ossec-csyslogd | grep -v grep"
  notifies :restart, 'service[ossec]'
end

template '/etc/rsyslog.d/60-localsyslog.conf' do
  source '60-localsyslog.erb'
  notifies :run, 'execute[restart_rsyslog]'
end

execute 'restart_rsyslog' do
  command 'service rsyslog restart'
  action :nothing
end

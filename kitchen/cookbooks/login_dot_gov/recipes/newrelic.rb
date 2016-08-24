include_recipe "newrelic"

license = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]['newrelic_license_key']

execute 'add NR license to sysmon config' do
  command "sed -i s/^license_key=/license_key=#{license}/ /etc/newrelic/nrsysmond.cfg"
  notifies :restart, "service[#{node['newrelic']['server_monitor_agent']['service_name']}]"
end

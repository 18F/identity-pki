# declare service for nessusagent
service 'nessusagent'

dl_key_path = '/tmp/nessus_dl.key'
# get download key
execute 'curl grep download key' do
  command "echo `curl -s \"https://www.tenable.com/products/nessus/agent-download#tos\" | grep -E -o 'timecheck.{0,43}' | cut -d '>' -f2` > #{dl_key_path}"
  not_if { ::File.exists? dl_key_path }
  notifies :create, "remote_file[#{node['identity-nessus']['deb_name']}]", :immediately
end

# download Nessus Agent debian package
remote_file node['identity-nessus']['deb_name'] do
  checksum node['identity-nessus']['sha256sum']
  path "/tmp/#{node['identity-nessus']['deb_name']}"
  source lazy { "http://downloads.nessus.org/nessus3dl.php?file=#{node['identity-nessus']['deb_name']}&licence_accept=yes&t=#{::File.read(dl_key_path).chomp}" }
  not_if { ::File.exists? '/etc/init.d/nessusagent' }
end

# install dpkg
dpkg_package 'NessusAgent' do
  action :install
  source "/tmp/#{node['identity-nessus']['deb_name']}"
  not_if { ::File.exists? '/etc/init.d/nessusagent' }
  notifies :start, 'service[nessusagent]'
end

# # link to nessus-manager
# bin = '/opt/nessus_agent/sbin/nessuscli'
# cmd = 'agent link'
# groups = 'All'
# host = 'jumphost.internal.login.gov'
# key = Chef::EncryptedDataBagItem.load('config', 'app')["#{node.chef_environment}"]["nessus_key"]
# node_name = node.name
# port = 8834
#
# execute 'nessuscli agent link' do
#   command = "#{bin} #{cmd} --groups=#{groups} --key=#{key} --host=#{host} --port=#{port}"
# end
